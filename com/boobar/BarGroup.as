import com.Utils.StringUtils;
import com.Utils.Archive;
import com.boobar.BarGroup;
import com.boobarcommon.Colours;
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
class com.boobar.BarGroup
{
	public static var NO_INTERRUPT_GROUP:String = "#1";
	public static var INTERRUPT_GROUP:String = "#2";
	
	private static var GROUP_PREFIX:String = "GROUP";
	private static var ID_PREFIX:String = "ID";
	private static var NAME_PREFIX:String = "Name";
	private static var COLOUR_PREFIX:String = "Colour";
	private static var FLASH_PREFIX:String = "Flash";
	
	private var m_id:String;
	private var m_name:String;
	private var m_colourName:String;
	private var m_screenFlash:Boolean;

	public function BarGroup(id:String, name:String, colourName:String, screenFlash:Boolean)
	{
		m_id = id;
		m_colourName = colourName;
		SetName(name);
		m_screenFlash = screenFlash;
	}

	public static function GetNextID(groups:Array):String
	{
		var lastCount:Number = 0;
		for (var indx:Number = 0; indx < groups.length; ++indx)
		{
			var thisGroup:BarGroup = groups[indx];
			if (thisGroup != null)
			{
				var thisID:String = thisGroup.GetID();
				var thisCount:Number = Number(thisID.substring(1, thisID.length));
				if (thisCount > lastCount)
				{
					lastCount = thisCount;
				}
			}
		}
		
		lastCount = lastCount + 1;
		return "#" + lastCount;
	}
	
	public static function GetGroupIndex(groups:Array, id:String):Number
	{
		var ret:Number = null;
		for (var indx:Number = 0; indx < groups.length; ++indx)
		{
			var thisGroup:BarGroup = groups[indx];
			if (thisGroup != null)
			{
				if (thisGroup.GetID() == id)
				{
					ret = indx;
					break;
				}
			}
		}
		
		return ret;
	}
	
	public static function GetUnusedColours(groups:Array):Array
	{
		var ret:Array = new Array();
		
		var colours:Object = new Object();
		var colourArray:Array = Colours.GetColourNames();
		for (var indx:Number = 0; indx < colourArray.length; ++indx)
		{
			colours[colourArray[indx]] = 1;
		}

		for (var indx:Number = 0; indx < groups.length; ++indx)
		{
			var thisGroup:BarGroup = groups[indx];
			if (thisGroup != null)
			{
				colours[thisGroup.GetColourName()] = 0;
			}
		}

		for (var indx in colours)
		{
			if (colours[indx] == 1)
			{
				ret.push(indx);
			}
		}
		
		return ret;
	}
	
	public function GetID():String
	{
		return m_id;
	}
	
	public function GetName():String
	{
		return m_name;
	}
	
	public function SetName(newName:String):Void
	{
		if (newName == null)
		{
			m_name = "";
		}
		else
		{
			m_name = StringUtils.Strip(newName);
		}
	}
	
	public function GetColourName():String
	{
		return m_colourName;
	}
	
	public function SetColourName(newName:String):Void
	{
		m_colourName = newName;
	}
	
	public function GetScreenFlash():Boolean
	{
		return m_screenFlash;
	}
	
	public function SetScreenFlash(newValue:Boolean):Void
	{
		m_screenFlash = newValue;
	}
	
	public function Save(archive:Archive, groupNumber:Number):Void
	{
		var prefix:String = GROUP_PREFIX + groupNumber;
		SetArchiveEntry(prefix, archive, BarGroup.ID_PREFIX, m_id);
		SetArchiveEntry(prefix, archive, BarGroup.NAME_PREFIX, m_name);
		SetArchiveEntry(prefix, archive, BarGroup.COLOUR_PREFIX, m_colourName);
		
		var tempFlash:String;
		if (m_screenFlash == true)
		{
			tempFlash = "1";
		}
		else
		{
			tempFlash = "0";
		}
		SetArchiveEntry(prefix, archive, BarGroup.FLASH_PREFIX, tempFlash);
	}
	
	public static function FromArchive(archive:Archive, groupNumber:Number):BarGroup
	{
		var ret:BarGroup = null;
		var prefix:String = GROUP_PREFIX + groupNumber;
		var id:String = GetArchiveEntry(prefix, archive, BarGroup.ID_PREFIX, null);
		if (id != null)
		{
			var name:String = GetArchiveEntry(prefix, archive, BarGroup.NAME_PREFIX, null);
			var colourName:String = GetArchiveEntry(prefix, archive, BarGroup.COLOUR_PREFIX, null);
			if (colourName == "Gray") colourName = Colours.GREY; // TEMP
			var tempFlash:String = GetArchiveEntry(prefix, archive, BarGroup.FLASH_PREFIX, "0");
			var screenFlash:Boolean = tempFlash == "1";
			ret = new BarGroup(id, name, colourName, screenFlash);
		}
		
		return ret;
	}

	public static function ClearArchive(archive:Archive, groupNumber:Number):Void
	{
		var prefix:String = GROUP_PREFIX + groupNumber;
		DeleteArchiveEntry(prefix, archive, BarGroup.ID_PREFIX);
		DeleteArchiveEntry(prefix, archive, BarGroup.NAME_PREFIX);
		DeleteArchiveEntry(prefix, archive, BarGroup.COLOUR_PREFIX);
		DeleteArchiveEntry(prefix, archive, BarGroup.FLASH_PREFIX);
	}

	private static function DeleteArchiveEntry(prefix:String, archive:Archive, key:String):Void
	{
		var keyName:String = prefix + "_" + key;
		archive.DeleteEntry(keyName);
	}
	
	private static function SetArchiveEntry(prefix:String, archive:Archive, key:String, value:String):Void
	{
		var keyName:String = prefix + "_" + key;
		archive.DeleteEntry(keyName);
		if (value != null && value != "null")
		{
			archive.AddEntry(keyName, value);
		}
	}
	
	private static function GetArchiveEntry(prefix:String, archive:Archive, key:String, defaultValue:String):String
	{
		var keyName:String = prefix + "_" + key;
		return archive.FindEntry(keyName, defaultValue);
	}
}