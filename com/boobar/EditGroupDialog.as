import com.Utils.Text;
import com.boocommon.Checkbox;
import com.boocommon.Colours;
import com.boocommon.Graphics;
import com.boocommon.MenuPanel;
import com.boocommon.ModalBase;
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
class com.boobar.EditGroupDialog
{
	private var m_modalBase:ModalBase;
	private var m_textFormat:TextFormat;
	private var m_groupName:String;
	private var m_colourName:String;
	private var m_screenFlash:Boolean;
	private var m_menu:MenuPanel;
	private var m_callback:Function;
	private var m_input:TextField;
	private var m_colourX:Number;
	private var m_colourY:Number;
	private var m_flashCheck:Checkbox;
	
	public function EditGroupDialog(name:String, parent:MovieClip, groupName:String, colourName:String, screenFlash:Boolean) 
	{
		m_groupName = groupName;
		m_colourName = colourName;
		m_screenFlash = screenFlash;
		
		m_modalBase = new ModalBase(name, parent, Delegate.create(this, DrawControls), 0.95);
		var modalMC:MovieClip = m_modalBase.GetMovieClip();
		var x:Number = modalMC._width / 4;
		var y:Number = modalMC._height - 10;
		m_modalBase.DrawButton("OK", modalMC._width / 4, y, Delegate.create(this, ButtonPressed));
		m_modalBase.DrawButton("Cancel", modalMC._width - (modalMC._width / 4), y, Delegate.create(this, ButtonPressed));
	}
	
	public function Show(callback:Function):Void
	{
		Selection.setFocus(m_input);
		Selection.setSelection(m_groupName.length, m_groupName.length);
		m_callback = callback;
		m_modalBase.Show(m_callback);
	}
	
	public function Hide():Void
	{
		Selection.setFocus(null);
		m_modalBase.Hide();
	}
	
	public function Unload():Void
	{
		Selection.setFocus(null);
		m_modalBase.Unload();
	}
	
	private function DrawControls(modalMC:MovieClip, textFormat:TextFormat):Void
	{
		m_textFormat = textFormat;
		
		var text1:String = "Group name";
		var labelExtents:Object;
		labelExtents = Text.GetTextExtent(text1, m_textFormat, modalMC);
		Graphics.DrawText("Line1", modalMC, text1, m_textFormat, modalMC._width / 2 - labelExtents.width / 2, 20, labelExtents.width, labelExtents.height);
		
		var input:TextField = modalMC.createTextField("Input", modalMC.getNextHighestDepth(), 30, labelExtents.height + 30, modalMC._width - 60, labelExtents.height + 6);
		input.type = "input";
		input.embedFonts = true;
		input.selectable = true;
		input.antiAliasType = "advanced";
		input.autoSize = false;
		input.border = true;
		input.background = false;
		input.setNewTextFormat(m_textFormat);
		input.text = m_groupName;
		input.borderColor = 0x585858;
		input.background = true;
		input.backgroundColor = 0x2E2E2E;
		input.wordWrap = false;
		input.maxChars = 40;
		m_input = input;
		
		var y:Number = input._y + input._height + 15;
		var checkSize:Number = 13;
		m_flashCheck = new Checkbox("FlashCheck", modalMC, 30, y, checkSize, null, m_screenFlash);
		
		var text2:String = "Flash screen";
		var hiddenExtents:Object;
		hiddenExtents = Text.GetTextExtent(text2, m_textFormat, modalMC);
		Graphics.DrawText("Line2", modalMC, text2, m_textFormat, 40 + checkSize, y + checkSize / 2 - hiddenExtents.height / 2, hiddenExtents.width, hiddenExtents.height);
		y += hiddenExtents.height + 10;
		
		m_colourX = 30;
		m_colourY = y;
		BuildMenu(modalMC, m_colourX, m_colourY);
	}
	
	private function BuildMenu(modalMC:MovieClip, x:Number, y:Number):Void
	{
		var colours:Array = Colours.GetColourArray(m_colourName);
		m_menu = new MenuPanel(modalMC, "Colour", 4, colours[0], colours[1]);
		var subMenu:MenuPanel = new MenuPanel(modalMC, "Colour", 4, colours[0], colours[1]);
		var colourArray:Array = Colours.GetColourNames();
		for (var indx:Number = 0; indx < colourArray.length; ++indx)
		{
			AddItem(subMenu, colourArray[indx]);
		}

		m_menu.AddSubMenu("Colour", subMenu, colours[0], colours[1]);
		
		var pt:Object = m_menu.GetDimensions(x, y, true, 0, 0, modalMC.width, modalMC.height);
		m_menu.Rebuild();
		m_menu.RebuildSubmenus();
		m_menu.SetVisible(true);
	}
	
	private function AddItem(subMenu:MenuPanel, colourName:String):Void
	{
		var colours:Array = Colours.GetColourArray(colourName);
		subMenu.AddItem(colourName, Delegate.create(this, ColourChanged), colours[0], colours[1]);
	}
	
	private function ColourChanged(colourName:String):Void
	{
		m_colourName = colourName;
		setTimeout(Delegate.create(this, RebuildMenu), 10);
	}
	
	private function RebuildMenu():Void
	{
		m_menu.Unload();
		BuildMenu(m_modalBase.GetMovieClip(), m_colourX, m_colourY);
	}
		
	private function ButtonPressed(text:String):Void
	{
		var success:Boolean = false;
		if (text == "OK")
		{
			success = true;
		}

		m_modalBase.Hide();
		
		if (m_callback != null)
		{
			if (success)
			{
				m_callback(m_input.text, m_colourName, m_flashCheck.IsChecked());
			}
			else
			{
				m_callback(null, null, false);
			}
		}
	}
}