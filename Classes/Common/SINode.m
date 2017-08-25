//
//  SINode.m
//  SIParser
//
//  Created by 杨晴贺 on 2017/8/25.
//  Copyright © 2017年 Silence. All rights reserved.
//

#import "SINode.h"

@implementation SINode

- (instancetype)initWithXmlNode:(xmlNodePtr)inNode {
    if (self = [super init]) {
        _node = inNode;
    }
    return self;
}

- (void)filterWithNodeFilter:(id<SINodeFilter>)inNodeFilter nodeList:(SINodeList *)outNodeList {
    if ([inNodeFilter filter:self]) {
        return;
    }
    [outNodeList addNode:self];
}

@end

@interface SINodeList()

@property (nonatomic, strong) NSMutableArray<SINode *> *nodes;

@end

@implementation SINodeList

- (instancetype)init {
    if (self = [super init]) {
        _nodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addNode:(SINode *)node {
    if (nil == node) {
        return;
    }
    [_nodes addObject:node];
}

- (void)addNodeList:(SINodeList *)nodeList{
    if (nil == [nodeList nodes]) {
        return;
    }
    [_nodes addObjectsFromArray:[nodeList nodes]];
}

- (NSUInteger)count{
    return _nodes.count;
}

- (SINode *)nodeWithIndex:(NSInteger)index{
    if (index >= _nodes.count) {
        return nil;
    }
    return _nodes[index];
}

- (NSArray<SINode *> *)nodes
{
    return _nodes;
}

- (SINode *)removeNodeWithIndex:(NSInteger)index{
    SINode *node = [self nodeWithIndex:index];
    if (node) {
        [_nodes removeObject:node];
    }
    return node;
}

- (void)removeAllNodes{
    [_nodes removeAllObjects];
}

- (BOOL)containsNode:(SINode *)node{
    if (nil == node) {
        return NO;
    }
    return [_nodes containsObject:node];
}

- (BOOL)removeNode:(SINode *)node{
    if (nil == node) {
        return NO;
    }
    [_nodes removeObject:node];
    return YES;
}

@end
