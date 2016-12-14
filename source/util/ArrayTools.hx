package util;

import de.polygonal.core.util.Assert.assert;

class ArrayTools {
  public static function swap<T>(array:Array<T>, a:Int, b:Int) {
    assert(array != null);
    assert(0 <= a && a < array.length);
    assert(0 <= b && b < array.length);

    if (a != b) {
      var x = array[a];
      array[a] = array[b];
      array[b] = x;
    }
  }

  public static function getFront<T>(array:Array<T>, index:Int) : T {
    assert(array != null);
    assert(0 <= index && index < array.length);

    swap(array, index, 0);
    return array[0];
  }

  private function new() {

  }
}