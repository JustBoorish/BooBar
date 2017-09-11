import com.Utils.StringUtils;
import com.Utils.Text;
import com.boobarcommon.Checkbox;
import com.boobarcommon.Colours;
import com.boobarcommon.Graphics;
import com.boobarcommon.ModalBase;
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
class com.boobar.EditSpellDialog
{
	private var m_modalBase:ModalBase;
	private var m_textFormat:TextFormat;
	private var m_spellName:String;
	private var m_npcName:String;
	private var m_callback:Function;
	private var m_input:TextField;
	private var m_anyNpcCheck:Checkbox;
	private var m_npcLabel:TextField;
	private var m_npcInput:TextField;
	
	public function EditSpellDialog(name:String, parent:MovieClip, parentWidth:Number, parentHeight:Number, spellName:String, npcName:String) 
	{
		m_spellName = spellName;
		m_npcName = npcName;
		
		m_modalBase = new ModalBase(name, parent, Delegate.create(this, DrawControls), parentWidth * 0.75, parentHeight * 0.7);
		var modalMC:MovieClip = m_modalBase.GetMovieClip();
		var x:Number = modalMC._width / 4;
		var y:Number = modalMC._height - 10;
		m_modalBase.DrawButton("OK", modalMC._width / 4, y, Delegate.create(this, ButtonPressed));
		m_modalBase.DrawButton("Cancel", modalMC._width - (modalMC._width / 4), y, Delegate.create(this, ButtonPressed));
	}
	
	public function Show(callback:Function):Void
	{
		Selection.setFocus(m_input);
		Selection.setSelection(m_spellName.length, m_spellName.length);
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
		
		var text1:String = "Spell name";
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
		input.text = m_spellName;
		input.borderColor = 0x585858;
		input.background = true;
		input.backgroundColor = 0x2E2E2E;
		input.wordWrap = false;
		input.maxChars = 40;
		m_input = input;
		
		var anyNPC:Boolean = m_npcName == "";
		var y:Number = input._y + input._height + 15;
		var checkSize:Number = 13;
		m_anyNpcCheck = new Checkbox("AnyNpcCheck", modalMC, 30, y, checkSize, Delegate.create(this, AnyNPCChanged), anyNPC);
		
		var text2:String = "Any NPC";
		var hiddenExtents:Object;
		hiddenExtents = Text.GetTextExtent(text2, m_textFormat, modalMC);
		Graphics.DrawText("Line2", modalMC, text2, m_textFormat, 40 + checkSize, y + checkSize / 2 - hiddenExtents.height / 2, hiddenExtents.width, hiddenExtents.height);
		y += hiddenExtents.height + 10;
		
		var text3:String = "Specific NPC Name";
		labelExtents = Text.GetTextExtent(text3, m_textFormat, modalMC);
		m_npcLabel = Graphics.DrawText("NPCLabel", modalMC, text3, m_textFormat, modalMC._width / 2 - labelExtents.width / 2, y, labelExtents.width, labelExtents.height);
		
		y += labelExtents.height + 10;
		input = modalMC.createTextField("Input", modalMC.getNextHighestDepth(), 30, y, modalMC._width - 60, labelExtents.height + 6);
		input.type = "input";
		input.embedFonts = true;
		input.selectable = true;
		input.antiAliasType = "advanced";
		input.autoSize = false;
		input.border = true;
		input.background = false;
		input.setNewTextFormat(m_textFormat);
		input.text = m_npcName;
		input.borderColor = 0x585858;
		input.background = true;
		input.backgroundColor = 0x2E2E2E;
		input.wordWrap = false;
		input.maxChars = 40;
		m_npcInput = input;
		
		AnyNPCChanged(anyNPC);
	}
	
	private function AnyNPCChanged(newValue:Boolean):Void
	{
		m_npcInput._visible = newValue != true;
		m_npcLabel._visible = newValue != true;
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
				var npcName:String = "";
				if (m_anyNpcCheck.IsChecked() != true)
				{
					npcName = StringUtils.Strip(m_npcInput.text);
				}
				
				m_callback(StringUtils.Strip(m_input.text), npcName);
			}
			else
			{
				m_callback(null, null);
			}
		}
	}
}