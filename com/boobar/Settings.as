import com.Utils.Archive;
import com.boobarcommon.DebugWindow;
/**
 * ...
 * @author ...
 */
class com.boobar.Settings
{
	private static var BAR_X:String = "BAR_X";
	private static var BAR_Y:String = "BAR_Y";
	private static var BAR_WIDTH:String = "BAR_WIDTH";
	private static var BAR_FONT_SIZE:String = "BAR_FONT_SIZE";
	private static var INTERRUPT_COLOUR:String = "INTERRUPT_COLOUR";
	private static var NO_INTERRUPT_COLOUR:String = "NO_INTERRUPT_COLOUR";
	private static var KNOWN_INTERRUPT_COLOUR:String = "KNOWN_INTERRUPT_COLOUR";
	private static var KNOWN_NO_INTERRUPT_COLOUR:String = "KNOWN_NO_INTERRUPT_COLOUR";
	
	public static var Separator:String = "|";
	public static var Enabled:String = "enabled";
	public static var X:String = "x";
	public static var Y:String = "y";
	public static var Width:String = "width";
	public static var Height:String = "height";
	public static var Alpha:String = "alpha";
	public static var Text:String = "text";
	public static var Font:String = "font";
	public static var Size:String = "size";
	public static var Colour:String = "colour";
	public static var Colour2:String = "colour2";
	public static var Delay:String = "delay";
	public static var TimeAdjustment:String = "timeadjust";

	public static var SizeSmall:String = "small";
	public static var SizeMedium:String = "medium";
	public static var SizeLarge:String = "large";
	
	public static var General:String = "General";
	
	private static var Version:String = "VERSION";

	private static var m_version:String = null;
	private static var m_archive:Archive = null;
	private static var m_fontArray:Array = null;

	public static function SetVersion(version:String):Void
	{
		m_version = version;
	}
	
	public static function SetArchive(archive:Archive):Void
	{
		m_archive = archive;
		
		if (m_archive != null)
		{
			m_archive.DeleteEntry(Version);
			m_archive.AddEntry(Version, m_version);
		}
	}
	
	public static function GetArchive():Archive
	{
		if (m_archive == null)
		{
			return new Archive();
		}
		
		return m_archive;
	}
	
	public static function Trim(inStr:String):String
	{
		if (inStr == null)
		{
			return "";
		}
		
		var ret:String = inStr;
		while (ret.charAt(ret.length - 1) == " ")
		{
			ret = ret.substr(0, ret.length - 1);
		}
		
		return ret;
	}
	
	public static function SizeToFontSize(inSize:String):Number
	{
		if (inSize == SizeSmall)
		{
			return 12;
		}
		else if (inSize == SizeMedium)
		{
			return 16;
		}
		else if (inSize = SizeLarge)
		{
			return 24;
		}
		
		return 12;
	}
	
	public static function GetArrayFromString(inArrayString:String):Array
	{
		if (inArrayString.indexOf("|") == -1)
		{
			var ret:Array = new Array();
			ret.push(inArrayString);
			return ret;
		}
		else
		{
			return inArrayString.split("|");
		}
	}
	
	public static function GetArrayString(inArray:Array):String
	{
		var arrayString:String = "";
		for (var i:Number = 0; i < inArray.length; i++)
		{
			if (i > 0)
			{
				arrayString = arrayString + "|";
			}
			
			arrayString = arrayString + inArray[i];
		}
		
		return arrayString;
	}

	public static function Save(prefix:String, settings:Object, defaults:Object):Void
	{
		if (m_archive == null)
		{
			DebugWindow.Log(DebugWindow.Error, "Settings.Save archive was null");
			return;
		}
		
		for (var prop in settings)
		{
			if (prop != undefined && settings[prop] != undefined && settings[prop] != defaults[prop])
			{
				var entryName:String = GetFullName(prefix, prop);
				m_archive.DeleteEntry(entryName);
				m_archive.AddEntry(entryName, settings[prop]);
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Save Set " + entryName + "=" + settings[prop] + " default=" + defaults[prop]);
			}
			else
			{
				m_archive.DeleteEntry(GetFullName(prefix, prop));
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Save Delete " + GetFullName(prefix, prop));
			}
		}
	}
	
	public static function Load(prefix:String, defaults:Object):Object
	{
		var settings:Object = new Object();
		
		for (var prop in defaults)
		{
			if (prop != undefined)
			{
				if (m_archive != null)
				{
					settings[prop] = m_archive.FindEntry(GetFullName(prefix, prop));
				}
			}
			
			if (settings[prop] == undefined)
			{
				settings[prop] = defaults[prop];
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Load Default " + GetFullName(prefix, prop) + "=" + settings[prop]);
			}
			else if (settings[prop] == defaults[prop])
			{
				if (m_archive != null)
				{
					m_archive.DeleteEntry(GetFullName(prefix, prop));
					//DebugWindow.Log(DebugWindow.Debug, "Settings.Load Delete " + GetFullName(prefix, prop));
				}
			}
			else
			{
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Load Get " + GetFullName(prefix, prop) + "=" + settings[prop]);
			}
		}
		
		return settings;
	}
	
	private static function GetFullName(prefix:String, name:String):String
	{
		return prefix + Separator + name;
	}
	
	public static function GetBarX(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[BAR_X];
		}
		
		return null;
	}
	
	public static function SetBarX(settings:Object, newX:Number):Void
	{
		if (settings != null && newX != null && newX >= 0)
		{
			settings[BAR_X] = newX;
		}
	}
	
	public static function GetBarY(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[BAR_Y];
		}
		
		return 4;
	}
	
	public static function SetBarY(settings:Object, newY:Number):Void
	{
		if (settings != null && newY != null && newY >= 0)
		{
			settings[BAR_Y] = newY;
		}
	}
	
	public static function GetBarWidth(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[BAR_WIDTH];
		}
		
		return null;
	}
	
	public static function SetBarWidth(settings:Object, newWidth:Number):Void
	{
		if (settings != null && newWidth != null && !isNaN(newWidth) && newWidth >= 50)
		{
			settings[BAR_WIDTH] = newWidth;
		}
	}
	
	public static function GetBarFontSize(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[BAR_FONT_SIZE];
		}
		
		return null;
	}
	
	public static function SetBarFontSize(settings:Object, newSize:Number):Void
	{
		if (settings != null && newSize != null && newSize >= 14)
		{
			settings[BAR_FONT_SIZE] = newSize;
		}
	}	
}
