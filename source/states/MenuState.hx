package states;

#if (!html5)
import flixel.addons.transition.FlxTransitionableState;
#end

import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.addons.editors.tiled.TiledObject;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBitmapTextButton;
import flixel.util.FlxColor;

using Lambda;
using ObjectInit;

class MenuState extends CommonState
{
  private var menuGuiLayer : TiledObjectLayer;
  private var _start : FlxBitmapTextButton;
  private var _about : FlxBitmapTextButton;
  private var _optionsButton : FlxBitmapTextButton;
  #if !html5
  private var _exitButton : FlxBitmapTextButton;
  #end
  private var _titleLetters : FlxTypedSpriteGroup<FlxBitmapText>;
  private var _logo : FlxSprite;
  private var _copyright : FlxBitmapText;
  private var gate : FlxTilemap;
  private var gateLayer : TiledTileLayer;

  override public function create():Void
  {
    super.create();

    _titleLetters = new FlxTypedSpriteGroup<FlxBitmapText>(Main.GAME_NAME.length);

    this.menuGuiLayer = cast(Assets.MainTilemap.getLayer("MenuState GUI"));
    this.gateLayer = cast(Assets.MainTilemap.getLayer("Gate"));
    this.gate = cast new FlxTilemap().loadMapFromArray(
      gateLayer.tileArray,
      gateLayer.width,
      gateLayer.height,
      'assets/${Assets.TileSet.imageSource}',
      Assets.TileSet.tileWidth,
      Assets.TileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );
    this.gate.useScaleHack = false;

    for (object in this.menuGuiLayer.objects) {
      switch (object.name) {
        case "Title":
          this._titleLetters.setPosition(object.x, object.y);
          this._titleLetters.solid = false;
          this._titleLetters.immovable = true;
          for (i in 0...Main.GAME_NAME.length) {
            var text = new FlxBitmapText(Assets.TitleFont);
            text.text = Main.GAME_NAME.charAt(i);
            text.setPosition(16*i, 0);
            text.solid = false;
            text.immovable = true;

            var currentPoint = FlxPoint.weak(_titleLetters.x + text.x, _titleLetters.y + text.y);
            FlxTween.linearPath(
              text,
              [
                currentPoint,
                FlxPoint.weak(_titleLetters.x + text.x, _titleLetters.y + text.y - 8),
                currentPoint,
                FlxPoint.weak(_titleLetters.x + text.x, _titleLetters.y + text.y + 8),
                currentPoint
              ],
              0.75,
              true,
              {
                startDelay: i * 0.1,
                loopDelay: 1,
                type: FlxTween.LOOPING
              }
            );
            this._titleLetters.add(text);
          }

        case "Play Button":
          this._start = makeButton(object, function() {
            #if (!html5)
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
            #end
            FlxG.switchState(new PlayState());
          });

        case "About Button":
          this._about = makeButton(object, function() {
            FlxG.switchState(new AboutState());
          });

        case "Options Button":
          this._optionsButton = makeButton(object, function() {
            #if (!html5)
            FlxTransitionableState.skipNextTransIn = true;
            FlxTransitionableState.skipNextTransOut = true;
            #end
            FlxG.switchState(new OptionsState());
          });
        #if !html5
        case "Exit Button":
          this._exitButton = makeButton(object, function() {
            Sys.exit(0);
          });
        #end


        case "Logo":
          var source = Assets.SpriteSet.getImageSourceByGid(object.gid).source;
          var index = source.lastIndexOf('/');
          var frameName = source.substr(index + 1);

          this._logo = new FlxSprite(object.x, object.y - object.height, 'assets/images/${frameName}').init(
            pixelPerfectPosition = false,
            pixelPerfectRender = false,
            immovable = true,
            solid = false
          );
        case "Copyright":
          var textColor = (object.properties.textColor == null) ? FlxColor.WHITE : FlxColor.fromString(object.properties.textColor);
          this._copyright = new FlxBitmapText(Assets.TextFont).init(
            x = object.x,
            y = object.y,
            autoSize = false,
            width = object.width,
            fieldWidth = object.width,
            text = object.properties.text,
            alignment = FlxTextAlign.LEFT,
            pixelPerfectPosition = false,
            pixelPerfectRender = false,
            letterSpacing = Std.parseInt(object.properties.letterSpacing),
            useTextColor = (object.properties.textColor != null),
            textColor = textColor,
            immovable = true,
            solid = false
          );
        default:
          // nop
      }
    }

    this.add(gate);
    this.add(_start);
    this.add(_about);
    this.add(_optionsButton);
    #if !html5
    this.add(_exitButton);
    #end
    this.add(_logo);
    this.add(_copyright);
    this.add(this._titleLetters);
    FlxG.console.registerObject("playButton", _start);
  }
}
