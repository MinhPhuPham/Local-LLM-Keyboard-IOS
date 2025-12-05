//
//  LRUCache.swift
//  LLM Local Keyboard
//
//  LRU (Least Recently Used) cache for prediction caching
//  iOS 15+ compatible
//

import Foundation

/// LRU Cache implementation for caching predictions
class LRUCache<Key: Hashable, Value> {
    
    // MARK: - Node Class
    
    private class Node {
        let key: Key
        var value: Value
        var prev: Node?
        var next: Node?
        
        init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
    
    // MARK: - Properties
    
    /// Cache storage
    private var cache: [Key: Node] = [:]
    
    /// Head of doubly-linked list (most recent)
    private var head: Node?
    
    /// Tail of doubly-linked list (least recent)
    private var tail: Node?
    
    /// Maximum cache capacity
    private let capacity: Int
    
    /// Current cache size
    var count: Int {
        return cache.count
    }
    
    // MARK: - Initialization
    
    /// Initialize cache with specified capacity
    /// - Parameter capacity: Maximum number of items to cache
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    // MARK: - Public Methods
    
    /// Get value for key
    /// - Parameter key: Key to lookup
    /// - Returns: Cached value, or nil if not found
    func get(_ key: Key) -> Value? {
        guard let node = cache[key] else {
            return nil
        }
        
        // Move to head (most recently used)
        moveToHead(node)
        
        return node.value
    }
    
    /// Set value for key
    /// - Parameters:
    ///   - key: Key to store
    ///   - value: Value to cache
    func set(_ key: Key, _ value: Value) {
        if let node = cache[key] {
            // Update existing node
            node.value = value
            moveToHead(node)
        } else {
            // Create new node
            let newNode = Node(key: key, value: value)
            cache[key] = newNode
            addToHead(newNode)
            
            // Check capacity
            if cache.count > capacity {
                removeTail()
            }
        }
    }
    
    /// Remove value for key
    /// - Parameter key: Key to remove
    func remove(_ key: Key) {
        guard let node = cache[key] else {
            return
        }
        
        removeNode(node)
        cache.removeValue(forKey: key)
    }
    
    /// Clear all cached items
    func clear() {
        cache.removeAll()
        head = nil
        tail = nil
    }
    
    // MARK: - Private Methods
    
    /// Add node to head of list
    private func addToHead(_ node: Node) {
        node.next = head
        node.prev = nil
        
        head?.prev = node
        head = node
        
        if tail == nil {
            tail = node
        }
    }
    
    /// Remove node from list
    private func removeNode(_ node: Node) {
        if node === head {
            head = node.next
        }
        
        if node === tail {
            tail = node.prev
        }
        
        node.prev?.next = node.next
        node.next?.prev = node.prev
    }
    
    /// Move node to head (mark as most recently used)
    private func moveToHead(_ node: Node) {
        guard node !== head else {
            return
        }
        
        removeNode(node)
        addToHead(node)
    }
    
    /// Remove tail (least recently used)
    private func removeTail() {
        guard let tailNode = tail else {
            return
        }
        
        removeNode(tailNode)
        cache.removeValue(forKey: tailNode.key)
    }
}
