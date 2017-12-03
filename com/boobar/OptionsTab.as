import com.Utils.Text;
import com.boobarcommon.Colours;
import com.boobarcommon.ComboBox;
import com.boobarcommon.Graphics;
import com.boobarcommon.ITabPane;
import com.boobarcommon.InfoWindow;
import com.boobarcommon.InventoryThrottle;
import com.boobarcommon.MenuPanel;
import com.boobarcommon.SubArchive;
import com.boobar.Castbar;
import com.boobar.Settings;
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
class com.boobar.OptionsTab implements ITabPane
{
	private var m_parent:MovieClip;
	private var m_addonMC:MovieClip;
	private var m_frame:MovieClip;
	private var m_name:String;
	private var m_maxWidth:Number;
	private var m_maxHeight:Number;
	private var m_margin:Number;
	private var m_settings:Object;
	private var m_fontSizeCombo:ComboBox;
	private var m_barWidthInput:TextField;
	private var m_castbar:Castbar;
	private var m_showBar:MovieClip;
	private var m_hideBar:MovieClip;
	
	public function OptionsTab(title:String, settings:Object)
	{
		m_name = title;
		m_settings = settings;
		m_parent = null;
	}
	
	public function CreatePane(addonMC:MovieClip, parent:MovieClip, name:String, x:Number, y:Number, width:Number, height:Number):Void
	{
		m_parent = parent;
		m_addonMC = addonMC;
		m_frame = m_parent.createEmptyMovieClip(name + "GeneralConfigWindow", m_parent.getNextHighestDepth());
		m_frame._visible = false;
		m_frame._x = x;
		m_frame._y = y;
		m_maxWidth = width;
		m_margin = 6;
		m_maxHeight = height;
		
		DrawFrame(addonMC);
	}
	
	public function GetVisible():Boolean
	{
		return m_frame._visible;
	}
	
	public function SetVisible(visible:Boolean):Void
	{
		m_frame._visible = visible;
		if (visible == true)
		{
			InitialiseSettings();
			
			m_showBar._visible = true;
			m_hideBar._visible = false;
		}
	}
	
	public function GetCoords():Object
	{
		var pt:Object = new Object();
		pt.x = m_frame._x;
		pt.y = m_frame._y;
		return pt;
	}
	
	public function Save():Void
	{
		if (m_settings != null)
		{
			Settings.SetBarFontSize(m_settings, 0, Number(m_fontSizeCombo.GetSelectedEntry()));
			Settings.SetBarWidth(m_settings, 0, Number(m_barWidthInput.text));
			
			if (m_castbar != null)
			{
				var pt:Object = m_castbar.GetCoords();
				Settings.SetBarX(m_settings, 0, pt.x);
				Settings.SetBarY(m_settings, 0, pt.y);
			}
			
			UnloadCastbar();
		}
	}
	
	public static function ApplyOptions(settings:Object):Void
	{
	}
	
	public function StartDrag():Void
	{
	}
	
	public function StopDrag():Void
	{
	}
	
	private function InitialiseSettings():Void
	{
		m_fontSizeCombo.SetSelectedEntry(String(Settings.GetBarFontSize(m_settings, 0)));
		m_barWidthInput.text = String(Settings.GetBarWidth(m_settings, 0));
	}
	
	private function DrawFrame(addonMC:MovieClip):Void
	{
		var textFormat:TextFormat = Graphics.GetTextFormat();

		var sizes:Array = [ "6", "8", "10", "12", "14", "16", "18", "20", "24", "28", "32" ];
		var text:String = "Bar font size";
		var extents:Object = Text.GetTextExtent(text, textFormat, m_frame);
		Graphics.DrawText("FontSizeText", m_frame, text, textFormat, 25, 35 - extents.height / 2, extents.width, extents.height);
		var comboX:Number = 35 + extents.width;
		var comboY:Number = 35 - extents.height / 2 - 4;
		
		text = "Bar width";
		extents = Text.GetTextExtent(text, textFormat, m_frame);
		var row:Number = 1;
		var y:Number = (40 + 2 * extents.height) * row;
		Graphics.DrawText("BarWidthLabel", m_frame, text, textFormat, 25, y, extents.width, extents.height);
		text = String(Settings.GetBarWidth(m_settings, 0));
		var sizeExtents:Object = Text.GetTextExtent("00000", textFormat, m_frame);
		m_barWidthInput = Graphics.DrawText("BarWidthInput", m_frame, text, textFormat, 30 + extents.width, y, sizeExtents.width, sizeExtents.height);
		m_barWidthInput.autoSize = false;
		m_barWidthInput.type = "input";
		m_barWidthInput.selectable = true;
		m_barWidthInput.border = true;
		m_barWidthInput.borderColor = 0x585858;
		m_barWidthInput.background = true;
		m_barWidthInput.backgroundColor = 0x2E2E2E;
		m_barWidthInput.wordWrap = false;
		m_barWidthInput.maxChars = 4;
		
		text = "Center bar horizontally";
		extents = Text.GetTextExtent(text, textFormat, m_frame);
		row = 3;
		y = 35 + (5 + 2 * extents.height) * row;
		Graphics.DrawButton("CenterBar", m_frame, text, textFormat, 25, y, extents.width, Colours.GetColourArray(Colours.GREY), Delegate.create(this, CenterBar));

		text = "Show draggable bar";
		row = 2;
		y = 35 + (5 + 2 * extents.height) * row;
		m_showBar = Graphics.DrawButton("MoveBar", m_frame, text, textFormat, 25, y, extents.width, Colours.GetColourArray(Colours.GREY), Delegate.create(this, MoveBar));
		
		text = "Hide draggable bar";
		row = 2;
		y = 35 + (5 + 2 * extents.height) * row;
		m_hideBar = Graphics.DrawButton("HideBar", m_frame, text, textFormat, 25, y, extents.width, Colours.GetColourArray(Colours.GREY), Delegate.create(this, HideBar));

		m_fontSizeCombo = new ComboBox(m_frame, "FontSizeCombo", addonMC, comboX, comboY, null, null, 6, String(Settings.GetBarFontSize(m_settings, 0)), sizes);
		m_fontSizeCombo.SetChangedCallback(Delegate.create(this, FontSizeChanged));
		
		InitialiseSettings();
	}
	
	private function MoveBar():Void
	{
		m_showBar._visible = false;
		m_hideBar._visible = true;
		CreateCastbar();
		m_castbar.EnableDragging();
	}
	
	private function HideBar():Void
	{
		m_showBar._visible = true;
		m_hideBar._visible = false;
		if (m_castbar != null)
		{
			Save();
			UnloadCastbar();
		}
	}
	
	private function CenterBar():Void
	{
		var isDragging:Boolean = m_castbar != null;
		Save();
		UnloadCastbar();
		Settings.SetBarX(m_settings, 0, Stage.width / 2 - Settings.GetBarWidth(m_settings, 0) / 2);
		if (isDragging == true)
		{
			CreateCastbar();
			m_castbar.EnableDragging();
		}
	}
	
	private function CreateCastbar():Void
	{
		m_showBar._visible = false;
		m_hideBar._visible = true;
		if (m_castbar == null)
		{
			m_castbar = new Castbar("Drag", m_addonMC, Settings.GetBarX(m_settings, 0), Settings.GetBarY(m_settings, 0), Settings.GetBarWidth(m_settings, 0), Settings.GetBarFontSize(m_settings, 0), false, null, null);
		}		
	}
	
	private function UnloadCastbar():Void
	{
		m_showBar._visible = true;
		m_hideBar._visible = false;
		if (m_castbar != null)
		{
			m_castbar.Unload();
			m_castbar = null;
		}		
	}
	
	private function FontSizeChanged(newValue:String):Void
	{
		if (m_castbar != null)
		{
			Save();
			UnloadCastbar();
			CreateCastbar();
			m_castbar.EnableDragging();
		}
	}
}