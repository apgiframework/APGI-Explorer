import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var name: String
    let dateCreated: Date
    var dateModified: Date
    var results: [String: Int]
}

protocol DataStore {
    func save<T: Codable>(_ value: T, forKey key: String) throws
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func delete(forKey key: String) throws
}

class UserDefaultsDataStore: DataStore {
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let data = try encoder.encode(value)
        defaults.set(data, forKey: key)
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try decoder.decode(type, from: data)
    }
    
    func delete(forKey key: String) throws {
        defaults.removeObject(forKey: key)
    }
}

class FileSystemDataStore: DataStore {
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func save<T: Codable>(_ value: T, forKey key: String) throws {
        let url = documentsDirectory.appendingPathComponent(key)
        let data = try encoder.encode(value)
        try data.write(to: url)
    }
    
    func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        let url = documentsDirectory.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try decoder.decode(type, from: data)
    }
    
    func delete(forKey key: String) throws {
        let url = documentsDirectory.appendingPathComponent(key)
        try fileManager.removeItem(at: url)
    }
}
