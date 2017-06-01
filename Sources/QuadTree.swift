//
//  QuadTree.swift
//  Cluster
//
//  Created by Lasha Efremidze on 5/6/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import MapKit

protocol AnnotationsContainer {
    func add(_ annotation: MKAnnotation) -> Bool
    func remove(_ annotation: MKAnnotation) -> Bool
    func annotations(in rect: MKMapRect) -> [MKAnnotation]
}

class QuadTreeNode {
    
    enum NodeType {
        case leaf
        case `internal`(children: Children)
    }
    
    struct Children: Sequence {
        let northWest: QuadTreeNode
        let northEast: QuadTreeNode
        let southWest: QuadTreeNode
        let southEast: QuadTreeNode
        
        init(parentNode: QuadTreeNode) {
            let mapRect = parentNode.rect
            northWest = QuadTreeNode(rect: MKMapRect(minX: mapRect.minX, minY: mapRect.minY, maxX: mapRect.midX, maxY: mapRect.midY))
            northEast = QuadTreeNode(rect: MKMapRect(minX: mapRect.midX, minY: mapRect.minY, maxX: mapRect.maxX, maxY: mapRect.midY))
            southWest = QuadTreeNode(rect: MKMapRect(minX: mapRect.minX, minY: mapRect.midY, maxX: mapRect.midX, maxY: mapRect.maxY))
            southEast = QuadTreeNode(rect: MKMapRect(minX: mapRect.midX, minY: mapRect.midY, maxX: mapRect.maxX, maxY: mapRect.maxY))
        }
        
        struct ChildrenIterator: IteratorProtocol {
            private var index = 0
            private let children: Children
            
            init(children: Children) {
                self.children = children
            }
            
            mutating func next() -> QuadTreeNode? {
                defer { index += 1 }
                switch index {
                case 0: return children.northWest
                case 1: return children.northEast
                case 2: return children.southWest
                case 3: return children.southEast
                default: return nil
                }
            }
        }
        
        public func makeIterator() -> ChildrenIterator {
            return ChildrenIterator(children: self)
        }
    }
    
    var annotations = [MKAnnotation]()
    let rect: MKMapRect
    var type: NodeType = .leaf
    
    static let maxPointCapacity = 8
    
    init(rect: MKMapRect) {
        self.rect = rect
    }
    
}

extension QuadTreeNode: AnnotationsContainer {
    
    @discardableResult
    func add(_ annotation: MKAnnotation) -> Bool {
        guard rect.contains(annotation.coordinate) else { return false }
        
        switch type {
        case .leaf:
            annotations.append(annotation)
            // if the max capacity was reached, become an internal node
            if annotations.count == QuadTreeNode.maxPointCapacity {
                subdivide()
            }
        case .internal(let children):
            // pass the point to one of the children
            for child in children where child.add(annotation) {
                return true
            }
            
            fatalError("rect.contains evaluted to true, but none of the children added the annotation")
        }
        return true
    }
    
    @discardableResult
    func remove(_ annotation: MKAnnotation) -> Bool {
        guard rect.contains(annotation.coordinate) else { return false }
        
        _ = annotations.map { $0.coordinate }.index(of: annotation.coordinate).map { annotations.remove(at: $0) }
        
        switch type {
        case .leaf: break
        case .internal(let children):
            // pass the point to one of the children
            for child in children where child.remove(annotation) {
                return true
            }
            
            fatalError("rect.contains evaluted to true, but none of the children removed the annotation")
        }
        return true
    }
    
    private func subdivide() {
        switch type {
        case .leaf:
            type = .internal(children: Children(parentNode: self))
        case .internal:
            preconditionFailure("Calling subdivide on an internal node")
        }
    }
    
    func annotations(in rect: MKMapRect) -> [MKAnnotation] {
        
        // if the node's rect and the given rect don't intersect, return an empty array,
        // because there can't be any points that lie the node's (or its children's) rect and
        // in the given rect
        guard self.rect.intersects(rect) else { return [] }
        
        var result = [MKAnnotation]()
        
        // collect the node's points that lie in the rect
        for annotation in annotations where rect.contains(annotation.coordinate) {
            result.append(annotation)
        }
        
        switch type {
        case .leaf: break
        case .internal(let children):
            // recursively add children's points that lie in the rect
            for childNode in children {
                result.append(contentsOf: childNode.annotations(in: rect))
            }
        }
        
        return result
    }
    
}

public class QuadTree: AnnotationsContainer {
    
    let root: QuadTreeNode
    
    public init(rect: MKMapRect) {
        self.root = QuadTreeNode(rect: rect)
    }
    
    @discardableResult
    public func add(_ annotation: MKAnnotation) -> Bool {
        return root.add(annotation)
    }
    
    @discardableResult
    public func remove(_ annotation: MKAnnotation) -> Bool {
        return root.remove(annotation)
    }
    
    public func annotations(in rect: MKMapRect) -> [MKAnnotation] {
        return root.annotations(in: rect)
    }
    
}
