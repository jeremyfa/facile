package facile;

import facile.ArrayPool;

using facile.Extensions;

class Immediate {

    var immediateCallbacks:Array<Void->Void> = [];

    var immediateCallbacksCapacity:Int = 0;

    var immediateCallbacksLen:Int = 0;

    public function new() {}

    /**
     * Schedule a callback that will be run when flush() is called
     */
    public function push(handleImmediate:Void->Void):Void {

        if (handleImmediate == null) {
            throw 'Immediate callback should not be null!';
        }

        if (immediateCallbacksLen < immediateCallbacksCapacity) {
            immediateCallbacks.unsafeSet(immediateCallbacksLen, handleImmediate);
            immediateCallbacksLen++;
        }
        else {
            immediateCallbacks[immediateCallbacksLen++] = handleImmediate;
            immediateCallbacksCapacity++;
        }

    }

    /** Execute and flush every awaiting callback, including the ones that
        could have been added with `push()` after executing the existing callbacks. */
    public function flush():Bool {

        var didFlush = false;

        // Immediate callbacks
        while (immediateCallbacksLen > 0) {

            didFlush = true;

            var pool = ArrayPool.pool(immediateCallbacksLen);
            var callbacks = pool.get();
            var len = immediateCallbacksLen;
            immediateCallbacksLen = 0;

            for (i in 0...len) {
                callbacks.set(i, immediateCallbacks.unsafeGet(i));
                immediateCallbacks.unsafeSet(i, null);
            }

            for (i in 0...len) {
                var cb:Dynamic = callbacks.get(i);
                cb();
            }

            pool.release(callbacks);

        }

        return didFlush;

    }

}
