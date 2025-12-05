//
//  MinHeap.swift
//  LLM Local Keyboard
//
//  Min-heap implementation for efficient top-K selection
//  iOS 15+ compatible
//

import Foundation

/// Generic min-heap data structure for top-K selection
class MinHeap<T> {
    
    // MARK: - Properties
    
    /// Internal heap storage
    private var heap: [T] = []
    
    /// Comparison function
    private let compare: (T, T) -> Bool
    
    /// Maximum heap size (for bounded heap)
    private let maxSize: Int
    
    /// Current heap size
    var count: Int {
        return heap.count
    }
    
    /// Check if heap is empty
    var isEmpty: Bool {
        return heap.isEmpty
    }
    
    // MARK: - Initialization
    
    /// Initialize a bounded min-heap
    /// - Parameters:
    ///   - maxSize: Maximum number of elements to keep
    ///   - compare: Comparison function (return true if first < second)
    init(maxSize: Int, compare: @escaping (T, T) -> Bool) {
        self.maxSize = maxSize
        self.compare = compare
    }
    
    // MARK: - Public Methods
    
    /// Insert an element into the heap
    /// - Parameter element: Element to insert
    func insert(_ element: T) {
        if heap.count < maxSize {
            // Heap not full, add element
            heap.append(element)
            bubbleUp(heap.count - 1)
        } else if !compare(element, heap[0]) {
            // Element is larger than minimum, replace minimum
            heap[0] = element
            bubbleDown(0)
        }
        // Otherwise, element is smaller than all elements, ignore
    }
    
    /// Extract all elements from the heap
    /// - Returns: Array of all elements
    func extractAll() -> [T] {
        return heap
    }
    
    /// Peek at the minimum element
    /// - Returns: Minimum element, or nil if empty
    func peek() -> T? {
        return heap.first
    }
    
    /// Remove and return the minimum element
    /// - Returns: Minimum element, or nil if empty
    func extractMin() -> T? {
        guard !heap.isEmpty else { return nil }
        
        if heap.count == 1 {
            return heap.removeLast()
        }
        
        let min = heap[0]
        heap[0] = heap.removeLast()
        bubbleDown(0)
        
        return min
    }
    
    /// Clear the heap
    func clear() {
        heap.removeAll()
    }
    
    // MARK: - Private Methods
    
    /// Bubble up element at index to maintain heap property
    private func bubbleUp(_ index: Int) {
        var child = index
        
        while child > 0 {
            let parent = (child - 1) / 2
            
            if compare(heap[child], heap[parent]) {
                heap.swapAt(child, parent)
                child = parent
            } else {
                break
            }
        }
    }
    
    /// Bubble down element at index to maintain heap property
    private func bubbleDown(_ index: Int) {
        var parent = index
        
        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var smallest = parent
            
            if left < heap.count && compare(heap[left], heap[smallest]) {
                smallest = left
            }
            
            if right < heap.count && compare(heap[right], heap[smallest]) {
                smallest = right
            }
            
            if smallest != parent {
                heap.swapAt(parent, smallest)
                parent = smallest
            } else {
                break
            }
        }
    }
}
