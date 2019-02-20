#import <XCTest/XCTest.h>
#import <nodle/nodle.h>

@interface AbstractNode (Test)
@property (nonatomic, readonly) NodeInput *testInput;
@property (nonatomic, readonly) NodeOutput *testOutput;
@end
@implementation AbstractNode (Test)
- (NodeInput *)testInput {return [self.inputs anyObject];}
- (NodeOutput *)testOutput {return [self.outputs anyObject];}
@end

@interface NodeTree (Tests)
@property (nonatomic, strong) NSMutableSet<id<Node>> *nodes;
@end

@interface NodeTreeTests : XCTestCase

@property (nonatomic, strong) AbstractNode *node1;
@property (nonatomic, strong) AbstractNode *node2;
@property (nonatomic, strong) AbstractNode *node3;
@property (nonatomic, strong) AbstractNode *node4;
@property (nonatomic, strong) AbstractNode *node5;
@property (nonatomic, strong) AbstractNode *node6;
@property (nonatomic, strong) NodeTree *nodeTree;

@end

@implementation NodeTreeTests

- (void)setUp {
    self.nodeTree = [NodeTree new];
    self.node1 = [AbstractNode new];
    self.node2 = [AbstractNode new];
    self.node3 = [AbstractNode new];
    self.node4 = [AbstractNode new];
    self.node5 = [AbstractNode new];
    self.node6 = [AbstractNode new];
}

- (void)tearDown {

}

#pragma mark - Chain

- (void)testAddingSingleBranchNodeChainHoldsAllNodes {
    [self.node1.testOutput addConnection:self.node2.testInput];
    [self.node2.testOutput addConnection:self.node3.testInput];
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node1]]];
    
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node1]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node2]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node3]);
}

- (void)testAddingSingleBranchNodeChainHoldsOnlyDownstreamNodesFromStartNode {
    [self.node1.testOutput addConnection:self.node2.testInput];
    [self.node2.testOutput addConnection:self.node3.testInput];
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node2]]];
    
    XCTAssertFalse([self.nodeTree.nodes containsObject:self.node1]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node2]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node3]);
}

- (void)testAddingBranchingNodeChainHoldsAllNodes {
    [self.node1.testOutput addConnection:self.node2.testInput];
    
    // Branch
    [self.node2.testOutput addConnection:self.node3.testInput];
    [self.node2.testOutput addConnection:self.node4.testInput];
    
    [self.node3.testOutput addConnection:self.node5.testInput];
    [self.node4.testOutput addConnection:self.node6.testInput];

    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node1]]];
    
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node1]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node2]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node3]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node4]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node5]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node6]);
}

#pragma mark - Outputs

- (void)testAddingBranchingNodeChainCollectsAllDanglingOutputsInAsTreeOutputs {
    [self.node1.testOutput addConnection:self.node2.testInput];
    
    // Branch
    [self.node2.testOutput addConnection:self.node3.testInput];
    [self.node2.testOutput addConnection:self.node4.testInput];
    
    [self.node3.testOutput addConnection:self.node5.testInput];
    [self.node4.testOutput addConnection:self.node6.testInput];
    
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node1]]];
    
    XCTAssertTrue([self.nodeTree.outputs containsObject:self.node5.testOutput]);
    XCTAssertTrue([self.nodeTree.outputs containsObject:self.node6.testOutput]);
    XCTAssertEqual([self.nodeTree.outputs count], 2);
}

#pragma mark - Inputs

- (void)testAddingMultipleStartNodesCollectsAllStartInputsAsTreeInputs {
    // Start nodes
    [self.node1.testOutput addConnection:self.node3.testInput];
    [self.node2.testOutput addConnection:self.node3.testInput];

    [self.node3.testOutput addConnection:self.node4.testInput];
    [self.node4.testOutput addConnection:self.node5.testInput];
    
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node1, self.node2]]];
    
    XCTAssertTrue([self.nodeTree.inputs containsObject:self.node1.testInput]);
    XCTAssertTrue([self.nodeTree.inputs containsObject:self.node2.testInput]);
    XCTAssertEqual([self.nodeTree.inputs count], 2);
}

- (void)testCallingHoldTwiceWithDifferentChainsClearsTree {
    // Chain 1
    [self.node1.testOutput addConnection:self.node3.testInput];
    [self.node2.testOutput addConnection:self.node3.testInput];
    
    // Chain 2
    [self.node4.testOutput addConnection:self.node5.testInput];
    [self.node5.testOutput addConnection:self.node6.testInput];

    // Test
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node1]]];
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithArray:@[self.node4]]];
    
    // Verify
    XCTAssertTrue([self.nodeTree.inputs containsObject:self.node4.testInput]);
    XCTAssertEqual([self.nodeTree.inputs count], 1);
    
    XCTAssertTrue([self.nodeTree.outputs containsObject:self.node6.testOutput]);
    XCTAssertEqual([self.nodeTree.outputs count], 1);

    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node4]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node5]);
    XCTAssertTrue([self.nodeTree.nodes containsObject:self.node6]);
    XCTAssertEqual([self.nodeTree.nodes count], 3);
}

- (void)testSerializingNodeTreeWithThreeNodesHasDataWithThreeNodes {
    [self.node1.testOutput addConnection:self.node2.testInput];
    [self.node2.testOutput addConnection:self.node3.testInput];
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithObject:self.node1]];
    NSDictionary *serialized = [(id)self.nodeTree serializedRepresentationAsDictionary];
    XCTAssertEqual([(NSArray *)serialized[@"data"][@"nodes"] count], 3);
}

- (void)testSerializingNodeTreeWithThreeNodesHasDataWithThreeConnections {
    [self.node1.testOutput addConnection:self.node2.testInput];
    [self.node2.testOutput addConnection:self.node3.testInput];
    [self.nodeTree holdNodeChainWithStartNodes:[NSSet setWithObject:self.node1]];
    NSDictionary *serialized = [(id)self.nodeTree serializedRepresentationAsDictionary];
    XCTAssertEqual([(NSArray *)serialized[@"data"][@"connections"] count], 3);
}


// TODO: Test -process triggers all startNodes -process
// TODO: Test -cancel triggers all startNodes -cancel

@end
