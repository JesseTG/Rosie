package entities;

// TODO: Turn this back into an ordinary enum (each flood-fill is doing string
// comparisons!)
@:enum
@:notNull
abstract BlockColor(String) {
  var Red = "tile-red.png";
  var Blue = "tile-blue.png";
  var Green = "tile-green.png";
  var Yellow = "tile-yellow.png";
  var Orange = "tile-orange.png";
  var Purple = "tile-purple.png";

  public static var All(default, null) = [Red, Blue, Green, Yellow, Orange, Purple];
}
