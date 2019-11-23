//
//  ObservationHelpers.h
//

#import <Foundation/Foundation.h>

typedef void (^NSObjectObservationBlock)(id observer, id changedValue);

@interface NSObject (ObservationHelpers)

/**
 Observes @c target.keyPath; calls selector on changes with changed value; cleans up automatically after self's -dealloc.
 @note Intended for updating views in reaction to model changes.

 @param target Object to monitor for changes to @p keyPath.
 @param keyPath KVO key path to monitor.
 @param selector Selector to call on @c self when changes occur. Passed the new value that was set at @p keyPath. Nils out NSNulls.
                 Always called on the UI thread. Called immediately upon calling @c listenTo: for view initialization.
 */
- (void)listenTo:(NSObject *)target keyPath:(NSString *)keyPath selector:(SEL)selector;

/**
 Cleans up listeners early.
 */
- (void)stopListeningTo:(NSObject *)target;

@end


#ifdef DEBUG
bool selector_has_forbidden_prefix(NSString *);
#endif

