import com.Utils.StringUtils;
import com.Utils.Archive;
import com.boobar.KnownSpell;
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
class com.boobar.KnownSpell
{
	private static var SPELL_PREFIX:String = "SPELL";
	private static var ID_PREFIX:String = "ID";
	private static var NAME_PREFIX:String = "Name";
	private static var NPC_PREFIX:String = "NPC";
	private static var GROUP_PREFIX:String = "Group";
	
	private var m_id:String;
	private var m_name:String;
	private var m_group:String;
	private var m_npc:String;
	
	public function KnownSpell(id:String, name:String, npcName:String, group:String)
	{
		m_id = id;
		SetNPCName(npcName);
		SetName(name);
		m_group = group;
	}

	public static function GetNextID(spells:Object):String
	{
		var lastCount:Number = 0;
		for (var indx in spells)
		{
			var thisSpell:KnownSpell = spells[indx];
			if (thisSpell != null)
			{
				var thisID:String = thisSpell.GetID();
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
	
	public static function FindSpell(spells:Object, name:String, npc:String):KnownSpell
	{
		var ret:KnownSpell = null;
		for (var indx in spells)
		{
			var thisSpell:KnownSpell = spells[indx];
			if (thisSpell != null)
			{
				if (thisSpell.GetName() == name && thisSpell.GetNPCName() == npc)
				{
					ret = thisSpell;
					break;
				}
			}
		}
		
		return ret;
	}
	
	public static function GetOrderedEntries(groupID:String, spells:Object):Array
	{
		var spellNames:Array = new Array();
		var groupSpells:Object = new Object();
		for (var indx in spells)
		{
			var thisSpell:KnownSpell = spells[indx];
			if (thisSpell != null && thisSpell.GetGroup() == groupID)
			{
				groupSpells[thisSpell.GetID()] = thisSpell;
				spellNames.push(thisSpell.GetName());
			}
		}
		
		spellNames.sort();
		
		var ret:Array = new Array();
		for (var indx:Number = 0; indx < spellNames.length; ++indx)
		{
			for (var i in groupSpells)
			{
				var thisSpell:KnownSpell = groupSpells[i];
				if (thisSpell != null && thisSpell.GetName() == spellNames[indx])
				{
					ret.push(thisSpell);
				}
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
	
	public function GetGroup():String
	{
		return m_group;
	}
	
	public function SetGroup(newGroup:String):Void
	{
		if (newGroup == null)
		{
			m_group = "";
		}
		else
		{
			m_group = newGroup;
		}
	}
	
	public function GetNPCName():String
	{
		return m_npc;
	}
	
	public function SetNPCName(newName:String):Void
	{
		if (newName == null)
		{
			m_npc = "";
		}
		else
		{
			m_npc = StringUtils.Strip(newName);
		}
	}
	
	public function Save(archive:Archive, groupNumber:Number):Void
	{
		var prefix:String = SPELL_PREFIX + groupNumber;
		SetArchiveEntry(prefix, archive, KnownSpell.ID_PREFIX, m_id);
		SetArchiveEntry(prefix, archive, KnownSpell.NAME_PREFIX, m_name);
		SetArchiveEntry(prefix, archive, KnownSpell.NPC_PREFIX, m_npc);
		SetArchiveEntry(prefix, archive, KnownSpell.GROUP_PREFIX, m_group);
	}
	
	public static function FromArchive(archive:Archive, groupNumber:Number):KnownSpell
	{
		var ret:KnownSpell = null;
		var prefix:String = SPELL_PREFIX + groupNumber;
		var id:String = GetArchiveEntry(prefix, archive, KnownSpell.ID_PREFIX, null);
		if (id != null)
		{
			var name:String = GetArchiveEntry(prefix, archive, KnownSpell.NAME_PREFIX, null);
			var colourName:String = GetArchiveEntry(prefix, archive, KnownSpell.NPC_PREFIX, null);
			var group:String = GetArchiveEntry(prefix, archive, KnownSpell.GROUP_PREFIX, null);
			ret = new KnownSpell(id, name, colourName, group);
		}
		
		return ret;
	}

	public static function ClearArchive(archive:Archive, groupNumber:Number):Void
	{
		var prefix:String = SPELL_PREFIX + groupNumber;
		DeleteArchiveEntry(prefix, archive, KnownSpell.ID_PREFIX);
		DeleteArchiveEntry(prefix, archive, KnownSpell.NAME_PREFIX);
		DeleteArchiveEntry(prefix, archive, KnownSpell.NPC_PREFIX);
		DeleteArchiveEntry(prefix, archive, KnownSpell.GROUP_PREFIX);
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