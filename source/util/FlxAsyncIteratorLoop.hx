package util;

import flixel.FlxBasic;

/**
 * Asynchronously iterate over any Iterator; very useful for splitting up work
 * over several frames, or for certain kinds of animations or effects.
 *
 * FlxAsyncIteratorLoops cannot be reused; once they run their course, use a new
 * one.
 */
class FlxAsyncIteratorLoop<T> extends FlxBasic
{
  /**
   * Returns true if start() has been called at any point.
   */
  public var started(get, never) : Bool;

  /**
   * Returns true if the provided Iterator has been exhausted.
   */
  public var finished(get, never) : Bool;
  public var state(default, null) : State;
  private var _curIndex : Int;
  private var _iterationsPerUpdate : Int;
  private var _callback : T->Void;
  private var _iterator : Iterator<T>;
  private var _onStart : Void->Void;
  private var _onFinish : Void->Void;


  /**
   * Creates an instance of the FlxAsyncLoop class, used to do a loop while still allowing update() to get called and the screen to refresh.
   *
   * @param Iterations    How many total times should it loop
   * @param Callback    The function that should be called each loop
   * @param IterationsPerUpdate Optional: how many loops before we allow an update() - defaults to 100.
   */
  public function new(
    It:Iterator<T>,
    Callback:T->Void,
    ?OnStart:Void->Void,
    ?OnFinish:Void->Void,
    IterationsPerUpdate:Int = 100
  )
  {
    super();
    _curIndex = 0;
    _callback = Callback;
    _iterationsPerUpdate = IterationsPerUpdate;
    state = NotStarted;
    visible = false;
    _onStart = OnStart;
    _onFinish = OnFinish;
    _iterator = It;
  }

  /**
   * Start the loop (if it's not already started or finished)
   */
  public function start():Void
  {
    if (finished || started)
      return;

    _curIndex = 0;
    state = Idle;
    if (_onStart != null) {
      _onStart();
    }
  }

  private inline function get_started()
  {
    return state != NotStarted;
  }

  private inline function get_finished()
  {
    return state == Done;
  }

  override public function update(elapsed:Float):Void
  {
    if (!started || finished)
      return;

    _curIndex = (_curIndex + 1) % _iterationsPerUpdate;

    if (_curIndex == 0) {
      // call our function
      state = Running;
      _callback(_iterator.next());
      state = Idle;
    }

    if (!_iterator.hasNext()) {
      state = Done;
      if (_onFinish != null) {
        _onFinish();
      }
    }

    super.update(elapsed);
  }


  override public function destroy():Void
  {
    _callback = null;
    _iterator = null;
    _onStart = null;
    _onFinish = null;
    super.destroy();
  }
}

enum State {
  NotStarted;
  Idle;
  Running;
  Done;
}