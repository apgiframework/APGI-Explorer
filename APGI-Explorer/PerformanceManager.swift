import Foundation
import SwiftUI
import Combine

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Performance Manager

class PerformanceManager: ObservableObject {
    static let shared = PerformanceManager()

    @Published var memoryWarning = false
    @Published var performanceMode: PerformanceMode = .balanced

    private var cancellables = Set<AnyCancellable>()
    private let memoryMonitor = MemoryMonitor()

    enum PerformanceMode {
        case power
        case balanced
        case memory

        var cacheLimit: Int {
            switch self {
            case .power: return 200
            case .balanced: return 100
            case .memory: return 50
            }
        }

        var imageQuality: ImageQuality {
            switch self {
            case .power: return .high
            case .balanced: return .medium
            case .memory: return .low
            }
        }
    }

    enum ImageQuality {
        case low, medium, high

        var compressionQuality: CGFloat {
            switch self {
            case .low: return 0.3
            case .medium: return 0.7
            case .high: return 1.0
            }
        }
    }

    private init() {
        setupMemoryMonitoring()
        setupPerformanceModeDetection()
    }

    private func setupMemoryMonitoring() {
        memoryMonitor.$memoryPressure
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pressure in
                switch pressure {
                case .warning, .critical:
                    self?.memoryWarning = true
                    self?.adjustForLowMemory()
                case .normal:
                    self?.memoryWarning = false
                }
            }
            .store(in: &cancellables)
    }

    private func setupPerformanceModeDetection() {
        #if os(macOS)
        // Check if device is on battery power
        _ = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updatePerformanceMode()
        }
        #endif
    }

    #if os(macOS)
    private func updatePerformanceMode() {
        let isOnBattery = !ProcessInfo.processInfo.isLowPowerModeEnabled
        performanceMode = isOnBattery ? .memory : .power
    }
    #endif

    private func adjustForLowMemory() {
        // Clear caches
        LazyLoadCache<AnyHashable, Any>.shared.clearExpiredItems()
        ImageCache.shared.clearCache()

        // Switch to memory-efficient mode
        performanceMode = .memory

        // Notify views to optimize
        NotificationCenter.default.post(name: .memoryWarning, object: nil)
    }
}

// MARK: - Memory Monitor

class MemoryMonitor: ObservableObject {
    @Published var memoryPressure: MemoryPressure = .normal

    enum MemoryPressure {
        case normal, warning, critical
    }

    private var source: DispatchSourceMemoryPressure?

    init() {
        setupMemoryPressureMonitoring()
    }

    private func setupMemoryPressureMonitoring() {
        source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)

        source?.setEventHandler { [weak self] in
            guard let self = self else { return }

            let event = self.source?.mask
            if event?.contains(.critical) == true {
                self.memoryPressure = .critical
            } else if event?.contains(.warning) == true {
                self.memoryPressure = .warning
            }
        }

        source?.resume()
    }

    deinit {
        source?.cancel()
    }
}

// MARK: - Cache Instance Manager

private enum CacheInstanceManager {
    private static let queue = DispatchQueue(label: "CacheInstanceManager.instances", attributes: .concurrent)
    private static var _instances: [String: Any] = [:]

    static func shared<Key: Hashable, Value>() -> LazyLoadCache<Key, Value> {
        let key = "\(Key.self)-\(Value.self)"
        return queue.sync {
            if let instance = _instances[key] as? LazyLoadCache<Key, Value> {
                return instance
            }
            let newInstance = LazyLoadCache<Key, Value>()
            _instances[key] = newInstance
            return newInstance
        }
    }
}

// MARK: - Lazy Load Cache

class LazyLoadCache<Key: Hashable, Value> {
    static var shared: LazyLoadCache<Key, Value> {
        return CacheInstanceManager.shared()
    }

    private let cache = NSCache<NSCacheKey, CacheEntry>()
    private let queue = DispatchQueue(label: "LazyLoadCache", attributes: .concurrent)

    private class CacheEntry: NSObject {
        let value: Value
        let timestamp: Date
        let accessCount: Int

        init(value: Value, timestamp: Date, accessCount: Int) {
            self.value = value
            self.timestamp = timestamp
            self.accessCount = accessCount
            super.init()
        }
    }

    private class NSCacheKey: NSObject {
        let key: Key

        init(key: Key) {
            self.key = key
            super.init()
        }

        override var hash: Int {
            return key.hashValue
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? NSCacheKey else { return false }
            return other.key == key
        }
    }

    init() {
        setupCache()
    }

    private func setupCache() {
        cache.countLimit = PerformanceManager.shared.performanceMode.cacheLimit
        cache.totalCostLimit = 100 * 1024 * 1024 // 100MB

        // Set up eviction handler with strong reference
        let delegate = CacheDelegate()
        cache.delegate = delegate
        // Store delegate strongly to prevent deallocation
        objc_setAssociatedObject(cache, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    func getValue(for key: Key, loader: @escaping () async throws -> Value) async throws -> Value {
        let cacheKey = NSCacheKey(key: key)

        // Try cache first
        if let cachedValue = getCachedValue(for: cacheKey) {
            return cachedValue
        }

        // Load value asynchronously
        let value = try await loader()

        // Cache the value
        setCachedValue(value, for: cacheKey)

        return value
    }

    private func getCachedValue(for key: NSCacheKey) -> Value? {
        return queue.sync {
            return cache.object(forKey: key)?.value
        }
    }

    private func setCachedValue(_ value: Value, for key: NSCacheKey) {
        queue.async(flags: .barrier) {
            let entry = CacheEntry(value: value, timestamp: Date(), accessCount: 1)
            self.cache.setObject(entry, forKey: key, cost: self.calculateCost(value))
        }
    }

    private func calculateCost(_ value: Value) -> Int {
        // Simple cost estimation - can be customized per type
        if let data = value as? Data {
            return data.count
        } else if value is Image {
            return 1024 * 1024 // Estimate 1MB per image
        }
        return 1024 // Default 1KB
    }

    func clearExpiredItems() {
        queue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
    }
}

// MARK: - Cache Delegate

private class CacheDelegate: NSObject {
    func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: AnyObject?) {
        // Log evictions for debugging
        if let obj = obj {
            print("Cache evicted object: \(obj)")
        }
    }
}

// MARK: - NSCacheDelegate Conformance

extension CacheDelegate: NSCacheDelegate {
}

// MARK: - Image Cache

class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, CachedImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private class CachedImage: NSObject {
        let image: Image
        let timestamp: Date
        let size: Int64

        init(image: Image, timestamp: Date, size: Int64) {
            self.image = image
            self.timestamp = timestamp
            self.size = size
            super.init()
        }
    }

    private init() {
        cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache")

        setupCache()
        createCacheDirectory()
    }

    private func setupCache() {
        cache.countLimit = 100
        cache.totalCostLimit = 200 * 1024 * 1024 // 200MB
    }

    private func createCacheDirectory() {
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func image(for url: URL) async -> Image? {
        let key = url.absoluteString as NSString

        // Try memory cache first
        if let cached = cache.object(forKey: key) {
            return cached.image
        }

        // Try disk cache
        if let diskImage = await loadImageFromDisk(url: url) {
            cache.setObject(CachedImage(image: diskImage, timestamp: Date(), size: 0), forKey: key)
            return diskImage
        }

        // Load from network
        if let networkImage = await loadImageFromNetwork(url: url) {
            cache.setObject(CachedImage(image: networkImage, timestamp: Date(), size: 0), forKey: key)
            await saveImageToDisk(networkImage, url: url)
            return networkImage
        }

        return nil
    }

    private func loadImageFromDisk(url: URL) async -> Image? {
        let fileName = url.lastPathComponent
        let fileURL = cacheDirectory.appendingPathComponent(fileName)

        guard let data = try? Data(contentsOf: fileURL) else { return nil }

        #if os(iOS)
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif

        return nil
    }

    private func loadImageFromNetwork(url: URL) async -> Image? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            #if os(iOS)
            if let uiImage = UIImage(data: data) {
                return Image(uiImage: uiImage)
            }
            #elseif os(macOS)
            if let nsImage = NSImage(data: data) {
                return Image(nsImage: nsImage)
            }
            #endif
        } catch {
            print("Failed to load image from network: \(error)")
        }

        return nil
    }

    private func saveImageToDisk(_ image: Image, url: URL) async {
        // This would require converting Image back to Data
        // Implementation depends on specific requirements
    }

    func clearCache() {
        cache.removeAllObjects()

        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        createCacheDirectory()
    }
}

// MARK: - Lazy Loading View Modifier

struct LazyLoadView<Data: Hashable, Content: View>: View {
    let data: Data
    let content: (Data) -> Content

    @State private var isVisible = false
    @State private var hasAppeared = false

    var body: some View {
        Group {
            if isVisible {
                content(data)
                    .onAppear {
                        hasAppeared = true
                    }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            if !hasAppeared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isVisible = true
                }
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let memoryWarning = Notification.Name("MemoryWarning")
    static let performanceModeChanged = Notification.Name("PerformanceModeChanged")
}

// MARK: - Memory Efficient View Modifier

struct MemoryEfficient: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .memoryWarning)) { _ in
                // Clear non-essential state when memory is low
            }
    }
}

extension View {
    func memoryEfficient() -> some View {
        modifier(MemoryEfficient())
    }
}

// MARK: - Performance Tracking

class PerformanceTracker: ObservableObject {
    @Published var metrics = [String: TimeInterval]()

    func track<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        DispatchQueue.main.async {
            self.metrics[operation] = timeElapsed
        }

        return result
    }

    func trackAsync<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

        DispatchQueue.main.async {
            self.metrics[operation] = timeElapsed
        }

        return result
    }
}

// MARK: - View Extensions for Lazy Loading

extension View {
    func lazyLoad<Data: Hashable, Content: View>(
        data: Data,
        @ViewBuilder content: @escaping (Data) -> Content
    ) -> some View {
        LazyLoadView(data: data, content: content)
    }
}
