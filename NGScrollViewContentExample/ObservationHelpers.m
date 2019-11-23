//
//  ObservationHelpers.m
//  Copyright (c) 2013 Loupe. All rights reserved.
//

#import <objc/runtime.h>

#import "ObservationHelpers.h"
#import "NGScrollViewcontentExample-Swift.h"

static inline void dispatch_UI(void (^block)(void)) NS_SWIFT_UNAVAILABLE("Use DispatchQueue API instead") {
    dispatch_async(dispatch_get_main_queue(), block);
}

static inline void soft_dispatch_UI(void (^block)(void)) NS_SWIFT_UNAVAILABLE("Use DispatchQueue API instead") {
    if (NSThread.isMainThread) {
        block();
    }
    else {
        dispatch_UI(block);
    }
}

@interface NSArray<ObjectType> (PlanGrid)
- (NSArray *)filter:(BOOL(^)(id element))filterBlock;
@end

@implementation NSArray (PlanGrid)

- (NSArray *)filter:(BOOL(^)(id element))filterBlock
{
    NSParameterAssert(filterBlock);
    if(!filterBlock) return nil;
    return [self filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return filterBlock(evaluatedObject);
    }]];
}

@end


static inline NSMutableArray * __nullable ___performMap(id<NSFastEnumeration> __nonnull source, __nonnull id (^ __nullable mapBlock)(__nonnull id))
{
    if (!mapBlock) return nil;
    NSMutableArray *result = [NSMutableArray new];
    for (id elem in source) {
        id value = mapBlock(elem);
        if (!value) {
            // We prefer to return a blatantly wrong `nil` rather than a subtly incorrect result.
            return nil;
        }
        [result addObject:value];
    }
    return result;
}

@interface NSMutableArray<ObjectType> (PlanGrid)
/// Maps elements in an array to another form using the given mapping block
/// @note Do not return @c nil in @c mapBlock.
- (NSMutableArray <id> *) map:(id (^)(ObjectType element))mapBlock;
@end

@implementation NSMutableArray (PlanGrid)

- (instancetype) map:(id (^)(id element))mapBlock
{
    // This is the same as the [NSArray map:] implementation, except that it returns an NSMutableArray.
    NSParameterAssert(mapBlock);
    return ___performMap(self, mapBlock);
}

- (instancetype)reverse
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for(id elem in self.reverseObjectEnumerator) {
        [array addObject:elem];
    }
    return array;
}

@end


// Private object that acts as the context argument for the KVO callback
@interface ObservationRecord : NSObject
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong) id target;
@property (nonatomic) SEL selector;
@end

@implementation ObservationRecord
@end

// Private object that holds the observation contexts and automatically cleans up on object destruction
@interface ObservationDispatcher : NSObject
@property (nonatomic, weak) id observer;
@property (nonatomic, strong) NSMutableArray *contexts;
@end

@implementation ObservationDispatcher

+ (void)_lock:(void(^)(void))lockBlock {
    static UnfairLock *lock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[UnfairLock alloc] init];
    });
    [lock lock];
    lockBlock();
    [lock unlock];
}

+ (NSHashTable *)records
{
    static NSHashTable *records;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        records = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPointerPersonality capacity:0];
    });
    return records;
}

+ (void)addRecord:(ObservationRecord *)record
{
    [self _lock:^{
        [[self records] addObject:record];
    }];
}

+ (void)removeRecords:(NSArray *)records
{
    [self _lock:^{
        for (ObservationRecord *record in records) {
            [[self records] removeObject:record];
        }
    }];
}

+ (ObservationRecord *)getRecord:(void *)context
{
    __block id result = nil;
    [self _lock:^{
        result = [[self records] member:(__bridge id)context];
    }];
    return result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    ObservationRecord *record = [ObservationDispatcher getRecord:context];
    if(!record) {
        return;
    }

    NSAssert([record isKindOfClass:[ObservationRecord class]], @"Not a record?!");

    SEL selector = record.selector;

    id newValue = change[NSKeyValueChangeNewKey];
    if ([newValue isEqual:[NSNull null]]) {
        newValue = nil;
    }

    __strong id observer = self.observer;
    if (observer == nil) {
        return;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    soft_dispatch_UI(^{
        [observer performSelector:selector withObject:newValue];
    });
#pragma clang diagnostic pop
}

- (void) addTarget:(NSObject *)target keyPath:(NSString *)keyPath action:(SEL)selector
{

    ObservationRecord *record = [ObservationRecord new];
    record.keyPath = keyPath;
    record.target = target;
    record.selector = selector;

    //thread-safe because we only mutate on the main thread
    if (self.contexts) {
        [self.contexts addObject:record];
    }
    else {
        self.contexts = [NSMutableArray arrayWithObject:record];
    }

    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial;
    [ObservationDispatcher addRecord:record];

    [target addObserver:self forKeyPath:keyPath options:options context:(void *)record];
}

- (void) removeRecordForTarget:(id)target
{

    NSArray *recordsForTarget = [self.contexts filter:^BOOL(ObservationRecord *element) {
        return element.target == target;
    }];

    [ObservationDispatcher removeRecords:recordsForTarget];

    for(ObservationRecord *record in recordsForTarget) {
        [target removeObserver:self forKeyPath:record.keyPath context:(__bridge void *)record];
        //no contention on contexts because we only touch it on the main thread
        [self.contexts removeObject:record];
    }
}

- (void) dealloc
{
    [ObservationDispatcher removeRecords:self.contexts];

    self.observer = nil;
    for (ObservationRecord *record in self.contexts) {
        [record.target removeObserver:self forKeyPath:record.keyPath context:(__bridge void *)record];
    }
}

@end




@implementation NSObject (ObservationHelpers)

- (ObservationDispatcher *)_getObservationDispatcher
{

    static const char unique;
    const void *key = &unique;

    // Obtain the helper object
    __block ObservationDispatcher *dispatcher = objc_getAssociatedObject(self, key);

    // If it doesn't exist, create one in a thread-safe manner
    if (!dispatcher) {
        // On main thread, so this is safe.
        dispatcher = [ObservationDispatcher new];
        dispatcher.observer = self;
        objc_setAssociatedObject(self, key, dispatcher, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    return dispatcher;
}

/**
 Registers a selector to be performed whenever @c observed.keyPath is changed; cleans up automatically.

 @param observer Object which is monitoring for changes; when this is dealloc'd, observation is cleaned up.
 @param keyPath KVO key path to monitor.
 @param selector What to perform when changes occur. Passed one arg, <new value for keyPath>. Nils out NSNulls.
 Always called on the UI thread. Called immediately upon calling @c addViewObserver: for view initialization.
 */
- (void)addViewObserver:(NSObject *)observer keyPath:(NSString *)keyPath action:(SEL)selector
{
    NSParameterAssert(observer != nil);
    NSParameterAssert(keyPath != nil);
    NSParameterAssert(selector != nil);
    if (!observer || !keyPath || !selector) {
        return;
    }

    if (!NSThread.isMainThread) {
        dispatch_UI(^{
            [self addViewObserver:observer keyPath:keyPath action:selector];
        });
        return;
    }

    ObservationDispatcher *dispatcher = [observer _getObservationDispatcher];
    [dispatcher addTarget:self keyPath:keyPath action:selector];
}

/**
 Removes observers early.
 */
- (void)removeAllSelectorsForViewObserver:(NSObject *)observer
{
    if (!observer) {
        return;
    }

    if (NSThread.isMainThread) {
        ObservationDispatcher *dispatcher = [observer _getObservationDispatcher];
        [dispatcher removeRecordForTarget:self];
    }
    else {
        // NOTE: Hopefully, we should never get here, as teardown is supposed to happen on the UI thread.
        //       Eventually, let's remove this whole clause and the isMainThread check.
        dispatch_sync(dispatch_get_main_queue(), ^{
            ObservationDispatcher *dispatcher = [observer _getObservationDispatcher];
            [dispatcher removeRecordForTarget:self];
        });
    }
}

#pragma mark - Public interface

- (void)listenTo:(NSObject *)target keyPath:(NSString *)keyPath selector:(SEL)selector
{

#ifdef DEBUG
    NSAssert(selector != nil, @"Nil selector for %@ & %@!", self, keyPath);
    NSString *sel = NSStringFromSelector(selector);
    NSAssert([self respondsToSelector:selector], @"I, %@, don't respond to %@!", self, sel);
    NSAssert(!selector_has_forbidden_prefix(sel), @"Selector %@ has a forbidden prefix!", sel);
#endif

    [target addViewObserver:self keyPath:keyPath action:selector];
}

- (void)stopListeningTo:(NSObject *)target
{

    [target removeAllSelectorsForViewObserver:self];
}

@end

#pragma mark - Sanity checking

#ifdef DEBUG

bool selector_has_forbidden_prefix(NSString *selector) {
    for (NSString *prefix in @[@"alloc", @"new", @"copy", @"mutableCopy"]) {
        if ([selector hasPrefix:prefix]) {
            return true;
        }
    }
    return false;
}

#endif

