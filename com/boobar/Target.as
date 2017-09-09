import com.GameInterface.Game.Character;
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
class com.boobar.Target
{
	private var m_character:Character;
	private var m_updateFunction:Function;
	private var m_intervalID:Number;
	private var m_currentSpell:String;
	private var m_canInterrupt:Boolean;
	private var m_name:String;
	
	public function Target(character:Character, updateFunction:Function) 
	{
		m_character = character;
		m_updateFunction = updateFunction;
		m_intervalID = -1;
		
		if (m_character != null)
		{
			m_character.SignalCommandStarted.Connect(SlotSignalCommandStarted, this);
			m_character.SignalCommandEnded.Connect(SlotSignalCommandEnded, this);
			m_character.SignalCommandAborted.Connect(SlotSignalCommandEnded, this);
			m_character.SignalStatChanged.Connect(SlotStatChanged, this);	
			m_character.ConnectToCommandQueue();
		}
	}
	
	public function Unload():Void
	{
		ClearInterval();
		if (m_character != null)
		{
			m_character.SignalCommandStarted.Disconnect(SlotSignalCommandStarted, this);
			m_character.SignalCommandEnded.Disconnect(SlotSignalCommandEnded, this);
			m_character.SignalCommandAborted.Disconnect(SlotSignalCommandEnded, this);
			m_character.SignalStatChanged.Disconnect(SlotStatChanged, this);
			m_character = null;
		}
	}

	public function GetName():String
	{
		if (m_name == null)
		{
			m_name = m_character.GetName();
		}
		
		return m_name;
	}
	
	private function ClearInterval():Void
	{
		if (m_intervalID != -1)
		{
			clearInterval(m_intervalID);
			m_intervalID = -1;
		}
	}
	
	private function StartInterval():Void
	{
		ClearInterval();
		m_intervalID = setInterval(Delegate.create(this, UpdateProgress), 20);
	}

	private function UpdateProgress():Void
	{
		var pct:Number = m_character.GetCommandProgress();
		if (pct == null || pct >= 1)
		{
			SlotSignalCommandEnded();
		}
		else
		{
			CallUpdate(pct);
		}
	}
	
	private function SlotSignalCommandStarted(name:String, progressBarType:Number, uninterruptable:Boolean):Void
	{
		m_currentSpell = name;
		if (m_currentSpell == null)
		{
			m_currentSpell = "";
		}
		
		m_canInterrupt = !uninterruptable;
		if (m_character.GetStat(_global.Enums.Stat.e_Uninterruptable, 2) > 0)
		{
			m_canInterrupt = false;
		}

		StartInterval();
		UpdateProgress();
	}
	
	private function SlotSignalCommandEnded():Void
	{
		if (m_intervalID != -1)
		{
			ClearInterval();
			FinishUpdate();
		}
	}

	private function SlotStatChanged(statID:Number):Void
	{
		if (m_intervalID != -1 && statID == _global.Enums.Stat.e_Uninterruptable)
		{
			if (m_character.GetStat(_global.Enums.Stat.e_Uninterruptable, 2) > 0)
			{
				m_canInterrupt = false;
				UpdateProgress();
			}
		}
	}
	
	private function CallUpdate(pct:Number):Void
	{
		if (m_updateFunction != null)
		{
			m_updateFunction(m_currentSpell, m_canInterrupt, pct);
		}
	}
	
	private function FinishUpdate():Void
	{
		if (m_updateFunction != null)
		{
			m_updateFunction(m_currentSpell, m_canInterrupt, null);
		}
	}
}