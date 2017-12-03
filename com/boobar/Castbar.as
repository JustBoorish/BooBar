import com.boobarcommon.DebugWindow;
import com.boobar.BarGroup;
import com.boobar.KnownSpell;
import com.boobarcommon.Graphics;
import com.boobarcommon.ScreenFlash;
import com.boobarcommon.Colours;
import com.Utils.Text;
import mx.utils.Delegate;
/**
 * There is no copyright on this code
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 * LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
 * NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * Author: Boorish
 */
class com.boobar.Castbar
{
	private static var BLANK_NPC:String = "|_~%~_|";
	private static var NO_INTERRUPT_BAR = 0;
	private static var INTERRUPT_BAR = 1;
	
	private var m_parent:MovieClip;
	private var m_frame:MovieClip;
	private var m_groups:Array;
	private var m_spells:Object;
	private var m_showNpcName:Boolean;
	private var m_scaleFrame:MovieClip;
	private var m_dragBar:MovieClip;
	private var m_bars:Array;
	private var m_flashes:Array;
	private var m_spellTextField:TextField;
	private var m_npcTextField:TextField;
	private var m_lastSpellName:String;
	private var m_lastNpcName:String;
	private var m_textFormat:TextFormat;
	private var m_scaleWidth:Number;
	private var m_dragging:Boolean;
	private var m_spellLookup:Object;
	private var m_hideCastbarID:Number;
	
	public function Castbar(name:String, parent:MovieClip, x:Number, y:Number, width:Number, inFontSize:Number, showNpcName:Boolean, groups:Array, spells:Object)
	{
		var fontSize:Number = inFontSize;
		if (fontSize == null || fontSize < 6)
		{
			fontSize = 14;
			DebugWindow.Log(DebugWindow.Debug, "Fontsize = " + inFontSize);
		}
		
		m_parent = parent;
		m_groups = groups;
		m_spells = spells;
		m_hideCastbarID = -1;
		m_showNpcName = showNpcName;
		m_textFormat = Graphics.GetBoldTextFormat();
		m_textFormat.size = inFontSize;
		m_frame = m_parent.createEmptyMovieClip("CastBar" + name, m_parent.getNextHighestDepth());
		
		var extents:Object = Text.GetTextExtent("TEST", m_textFormat, m_frame);
		var height:Number = extents.height + extents.height * 0.05 + 4;
		DebugWindow.Log(DebugWindow.Debug, "Height = " + height + " " + inFontSize);
		
		m_scaleFrame = m_frame.createEmptyMovieClip("ScaleFrame", m_frame.getNextHighestDepth());
		m_dragBar = CreateBar("DragBar", width, height, Colours.GetDefaultColourArray());
		
		m_bars = new Array();
		m_flashes = new Array();
		if (groups != null)
		{
			for (var indx:Number = 0; indx < groups.length; ++indx)
			{
				var thisGroup:BarGroup = groups[indx];
				if (thisGroup.GetHideBar() == true)
				{
					m_bars.push(null);
				}
				else
				{
					m_bars.push(CreateBar("Bar" + thisGroup.GetID(), width, height, Colours.GetColourArray(thisGroup.GetColourName())));
				}
				
				if (thisGroup.GetScreenFlash() == true)
				{
					m_flashes.push(new ScreenFlash("Flash" + thisGroup.GetID(), parent, 2.5, Colours.GetColourArray(thisGroup.GetColourName())));
				}
				else
				{
					m_flashes.push(null);
				}
			}
		}
		
		m_scaleWidth = m_scaleFrame._width;
		
		Graphics.DrawFilledRoundedRectangle(m_frame, 0x000000, 2, 0x000000, 50, 0, 0, width, height);
		
		m_frame._x = x;
		m_frame._y = y;
		
		m_dragBar.onPress = Delegate.create(this, onDragPress);
		m_dragBar.onRelease = Delegate.create(this, onDragRelease);
		m_dragBar._visible = false;
		m_dragging = false;
		
		SetVisible(false);
		
		CreateSpellLookup();
	}
	
	public function SetVisible(visible:Boolean):Void
	{
		m_frame._visible = visible;
		if (visible != true)
		{
			ClearHideCastbar();
			RemoveNpcName();
			
			for (var indx:Number = 0; indx < m_flashes.length; ++indx)
			{
				var thisFlash:ScreenFlash = m_flashes[indx];
				if (thisFlash != null)
				{
					thisFlash.SetVisible(false);
				}
			}
		}
		else
		{
			for (var indx:Number = 0; indx < m_flashes.length; ++indx)
			{
				var thisFlash:ScreenFlash = m_flashes[indx];
				var thisBar:MovieClip = m_bars[indx];
				if (thisFlash != null && thisBar != null)
				{
					thisFlash.SetVisible(thisBar._visible);
				}
			}
		}
	}
	
	public function GetVisible():Boolean
	{
		return m_frame._visible;
	}
	
	public function Unload():Void
	{
		m_frame.removeMovieClip();
		m_frame = null;
		
		RemoveNpcName();
		
		for (var indx:Number = 0; indx < m_flashes.length; ++indx)
		{
			var thisFlash:ScreenFlash = m_flashes[indx];
			if (thisFlash != null)
			{
				thisFlash.Unload();
			}
		}
	}
	
	public function EnableDragging():Void
	{
		RemoveNpcName();
		HideAllBars();
		m_dragBar._visible = true;
		SetVisible(true);
	}
	
	public function DisableDragging():Void
	{
		RemoveNpcName();
		HideAllBars();
		SetVisible(false);
		onDragRelease();
	}
	
	public function GetCoords():Object
	{
		var pt:Object = new Object();
		pt.x = m_frame._x;
		pt.y = m_frame._y;	
		return pt;
	}
	
	public function CenterHorizontally():Void
	{
		RemoveNpcName();
		if (m_frame != null)
		{
			m_frame._x = Stage.width / 2 - m_frame._width / 2;
		}
	}

	public function Update(currentSpell:String, npc:String, canInterrupt:Boolean, pct:Number):Void
	{
		ClearHideCastbar();
		if (pct == null || pct >= 1)
		{
			SetVisible(false);
			m_scaleFrame._width = m_scaleWidth;
		}
		else
		{
			HideAllBars();
			
			var thisGroup:Number = FindBarIndex(canInterrupt, currentSpell, npc);
			if (thisGroup == null)
			{
				SetVisible(false);
			}
			else
			{
				if (m_bars[thisGroup] != null)
				{
					m_bars[thisGroup]._visible = true;
				}
				
				if (m_lastSpellName != currentSpell)
				{
					m_lastSpellName = currentSpell;
					if (m_spellTextField != null)
					{
						m_spellTextField.removeTextField();
					}
					
					var extents:Object = Text.GetTextExtent(m_lastSpellName, m_textFormat, m_frame);
					m_spellTextField = Graphics.DrawText("SpellLabel", m_frame, m_lastSpellName, m_textFormat, m_frame._width / 2 - extents.width / 2, m_frame._height / 2 - extents.height / 2, extents.width, extents.height);
				}
				
				if (m_showNpcName == true && m_lastNpcName != npc)
				{
					RemoveNpcName();
					
					if (npc != "")
					{
						m_lastNpcName = npc;
						var extents:Object = Text.GetTextExtent(m_lastNpcName, m_textFormat, m_parent);
						m_npcTextField = Graphics.DrawText("NpcLabel", m_parent, m_lastNpcName, m_textFormat, m_frame._x - 10 - extents.width, m_frame._y + m_frame._height / 2 - extents.height / 2, extents.width, extents.height);
					}
				}
				
				m_scaleFrame._width = (m_scaleWidth * pct);
				
				m_hideCastbarID = setTimeout(Delegate.create(this, HideCastbar), 750);
				
				if (m_bars[thisGroup] != null)
				{
					SetVisible(true);
				}
				else
				{
					SetVisible(false);
					if (m_flashes[thisGroup] != null)
					{
						m_flashes[thisGroup].SetVisible(true);
					}
				}
			}
		}
	}
	
	private function FindBarIndex(canInterrupt:Boolean, spellName:String, npc:String):Number
	{
		var ret:Number = null;
		var spellDictionary:Object = m_spellLookup[spellName];
		if (spellDictionary == null)
		{
			if (canInterrupt == true)
			{
				ret = INTERRUPT_BAR;
			}
			else
			{
				ret = NO_INTERRUPT_BAR;
			}
		}
		else
		{
			var thisBar:Number = spellDictionary[npc];
			if (thisBar == null)
			{
				thisBar = spellDictionary[BLANK_NPC];
				if (thisBar == null)
				{
					if (canInterrupt == true)
					{
						ret = INTERRUPT_BAR;
					}
					else
					{
						ret = NO_INTERRUPT_BAR;
					}
				}
			}
			
			if (thisBar != null)
			{
				ret = thisBar;
			}
		}
		
		return ret;
	}
	
	private function CreateSpellLookup():Void
	{
		m_spellLookup = new Object();
		for (var indx in m_spells)
		{
			var thisSpell:KnownSpell = m_spells[indx];
			if (thisSpell != null)
			{
				var groupIndex:Number = BarGroup.GetGroupIndex(m_groups, thisSpell.GetGroup());
				if (groupIndex != null)
				{
					var spellDictionary:Object;
					if (m_spellLookup[thisSpell.GetName()] == null)
					{
						spellDictionary = new Object();
						m_spellLookup[thisSpell.GetName()] = spellDictionary;
					}
					else
					{
						spellDictionary = m_spellLookup[thisSpell.GetName()];
					}

					var npcName:String = thisSpell.GetNPCName();
					if (npcName == null || npcName == "")
					{
						npcName = BLANK_NPC;
					}
					
					spellDictionary[npcName] = groupIndex;
				}
			}
		}
	}
	
	private function HideAllBars():Void
	{
		for (var indx:Number = 0; indx < m_bars.length; ++indx)
		{
			var thisBar:MovieClip = m_bars[indx];
			if (thisBar != null)
			{
				thisBar._visible = false;
			}
		}
		
		m_dragBar._visible = false;
	}
	
	private function CreateBar(name:String, width:Number, height:Number, colours:Array):MovieClip
	{
		var bar:MovieClip = m_scaleFrame.createEmptyMovieClip(name, m_scaleFrame.getNextHighestDepth());
		Graphics.DrawGradientFilledRoundedRectangle(bar, 0x000000, 0, colours, 0, 0, width, height);
		return bar;
	}
	
	private function onDragPress():Void
	{
		m_frame.startDrag();
		m_dragging = true;
	}
	
	private function onDragRelease():Void
	{
		if (m_dragging == true)
		{
			m_frame.stopDrag();
			m_dragging = false;
		}
	}
	
	private function RemoveNpcName():Void
	{
		m_lastNpcName = null;
		if (m_npcTextField != null)
		{
			m_npcTextField.removeTextField();
			m_npcTextField = null;
		}
	}
	
	private function ClearHideCastbar():Void
	{
		if (m_hideCastbarID != -1)
		{
			clearTimeout(m_hideCastbarID);
			m_hideCastbarID = -1;
		}
	}
	
	private function HideCastbar():Void
	{
		SetVisible(false);
	}
}