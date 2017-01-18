package states;

import haxe.ds.Vector;

#if (!html5)
import flixel.addons.transition.FlxTransitionableState;
#end
import flixel.addons.display.FlxTiledSprite;
import flixel.addons.editors.tiled.TiledObjectLayer;
import flixel.addons.editors.tiled.TiledTileLayer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxBitmapText;
import flixel.text.FlxText.FlxTextAlign;
import flixel.tile.FlxTilemap;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxPool;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.util.FlxTimer;
import flixel.ui.FlxBitmapTextButton;

import de.polygonal.ds.List;
import de.polygonal.ds.tools.Assert.assert;
import de.polygonal.Printf;

import entities.Block;
import entities.BlockGrid;
import entities.GravityDirection;
import entities.GravityIndicator.GravityIndicatorState;
import entities.GravityIndicator;
import entities.GravityPanel;
import entities.Rosie;
import entities.RosieEmote.EmoteState;
import util.FlxAsyncIteratorLoop;

using Lambda;
using ObjectInit;

class OptionsState extends CommonState
{
  private var _optionsGui : TiledObjectLayer;
  private var _backButton : FlxBitmapTextButton;
  #if desktop
  private var _fullScreenButton : FlxBitmapTextButton;
  #end
  private var gateLayer : TiledTileLayer;

  override public function create():Void {
    super.create();

    this._optionsGui = cast(Assets.MainTilemap.getLayer("Options GUI"));
    this.gateLayer = cast(Assets.MainTilemap.getLayer("Gate"));
    var gate : FlxTilemap = cast new FlxTilemap().loadMapFromArray(
      gateLayer.tileArray,
      gateLayer.width,
      gateLayer.height,
      'assets/${Assets.TileSet.imageSource}',
      Assets.TileSet.tileWidth,
      Assets.TileSet.tileHeight,
      1 // Tiled uses 0-indexing, but I think FlxTilemap uses 1-indexing
    );
    gate.useScaleHack = false;


    for (object in this._optionsGui.objects) {
      switch (object.name) {
      case "Back Button":
        this._backButton = makeButton(object, function() {
          #if (!html5)
          FlxTransitionableState.skipNextTransIn = true;
          FlxTransitionableState.skipNextTransOut = true;
          #end
          FlxG.switchState(new MenuState());
        });
      #if desktop
      case "Fullscreen Button":
        this._fullScreenButton = makeButton(object, function() {
          FlxG.fullscreen = !FlxG.fullscreen;
          FlxG.save.data.fullscreen = FlxG.fullscreen;
          FlxG.save.flush();
        });
      #end
      }
    }

    this.add(gate);
    this.add(_backButton);

    #if desktop // TODO: Support fullscreen on browsers eventually
    this.add(_fullScreenButton);
    #end
  }
}