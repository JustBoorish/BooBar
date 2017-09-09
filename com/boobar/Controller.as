//Imports
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.Character;
import com.GameInterface.Input;
import com.Utils.Archive;
import com.Utils.ID32;
import com.Utils.StringUtils;
import com.boobar.Castbar;
import com.boobar.OptionsTab;
import com.boobar.SpellList;
import com.boobar.Target;
import com.boocommon.Colours;
import com.boocommon.DebugWindow;
import com.boocommon.TabWindow;
import com.boobar.BarGroup;
import com.boobar.BIcon;
import com.boobar.Controller;
import com.boobar.KnownSpell;
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
class com.boobar.Controller extends MovieClip
{
	private static var VERSION:String = "0.5";
	private static var SETTINGS_PREFIX:String = "BOOBAR";
	private static var MAX_GROUPS:Number = 75;
	private static var MAX_SPELLS:Number = 250;

	private static var m_instance:Controller = null;
	
	private var m_debug:DebugWindow = null;
	private var m_icon:BIcon;
	private var m_mc:MovieClip;
	private var m_defaults:Object;
	private var m_settings:Object;
	private var m_clientCharacter:Character;
	private var m_characterName:String;
	private var m_target:Target;
	private var m_castbar:Castbar;
	private var m_groups:Array;
	private var m_spells:Object;
	private var m_configWindow:TabWindow;
	private var m_optionsTab:OptionsTab;
	private var m_spellTab:SpellList;
	
	//On Load
	function onLoad():Void
	{
		Settings.SetVersion(VERSION);
		
		m_mc = this;
		m_instance = this;
		
		m_clientCharacter = Character.GetClientCharacter();
		
		if (m_debug == null)
		{
			if (m_clientCharacter != null && (m_clientCharacter.GetName() == "Boorish" || m_clientCharacter.GetName() == "Boor" || m_clientCharacter.GetName() == "BoorGirl"))
			{
				m_debug = new DebugWindow(m_mc, DebugWindow.Debug);
			}
			else
			{
				m_debug = new DebugWindow(m_mc, DebugWindow.Info);
			}
		}
		DebugWindow.Log(DebugWindow.Info, "BooBar Loaded");

		_root["boobar\\boobar"].OnModuleActivated = Delegate.create(this, OnModuleActivated);
		_root["boobar\\boobar"].OnModuleDeactivated = Delegate.create(this, OnModuleDeactivated);
		
		m_mc._x = 0;
		m_mc._y = 0;
		m_characterName = null;
		SetDefaults();
	}
	
	function OnModuleActivated(config:Archive):Void
	{
		Settings.SetArchive(config);
		DebugWindow.Log("BooBar OnModuleActivated: " + config.toString());
		
		if (Character.GetClientCharacter().GetName() != m_characterName)
		{
			if (m_characterName != null)
			{
				m_clientCharacter.SignalCharacterDied.Disconnect(PlayerDied, this);
				m_clientCharacter.SignalOffensiveTargetChanged.Disconnect(TargetChanged, this);
			}
			
			m_clientCharacter = Character.GetClientCharacter();
			m_characterName = m_clientCharacter.GetName();
			m_clientCharacter.SignalCharacterDied.Connect(PlayerDied, this);
			m_clientCharacter.SignalOffensiveTargetChanged.Connect(TargetChanged, this);
			
			DebugWindow.Log("BooBar OnModuleActivated: connect " + m_characterName);
			m_settings = Settings.Load(SETTINGS_PREFIX, m_defaults);
			LoadBarGroups();
			LoadKnownSpells();
			SetDefaultSpells();
			
			if (m_castbar != null)
			{
				m_castbar.Unload();
			}
			
			RecreateCastbar();
			
			m_icon = new BIcon(m_mc, _root["boobar\\boobar"].BooBarIcon, VERSION, Delegate.create(this, ToggleConfigVisible), null, null, Delegate.create(this, ToggleDebugVisible), m_settings[BIcon.ICON_X], m_settings[BIcon.ICON_Y]);
		}
		
		m_castbar.SetVisible(false);
	}
	
	function OnModuleDeactivated():Archive
	{		
		SaveSettings();
		ClearTarget();

		var ret:Archive = Settings.GetArchive();
		//DebugWindow.Log("BooBar OnModuleDeactivated: " + ret.toString());
		return ret;
	}
	
	private function SetDefaultSpells():Void
	{
		if (m_groups.length == 0)
		{
			m_groups.push(new BarGroup(BarGroup.GetNextID(m_groups), "Uninterruptable", Colours.GRAY, false));
			m_groups.push(new BarGroup(BarGroup.GetNextID(m_groups), "Interruptable", Colours.AQUA, false));
			
			m_spells = new Object();
			var specialInterruptGroup:BarGroup = new BarGroup(BarGroup.GetNextID(m_groups), "Special Interrupts", Colours.YELLOW, true);
			m_groups.push(specialInterruptGroup);
			
			AddKnownSpell("Charged Hack", "", specialInterruptGroup.GetID());
			AddKnownSpell("Mjolnir's Hammer", "", specialInterruptGroup.GetID());
			AddKnownSpell("Searing Brand", "", specialInterruptGroup.GetID());
			AddKnownSpell("Itzama's Wrath", "", specialInterruptGroup.GetID());
			AddKnownSpell("Hot Iron", "", specialInterruptGroup.GetID());
			AddKnownSpell("Painwheel Overdrive", "", specialInterruptGroup.GetID());
			AddKnownSpell("Demolish", "", specialInterruptGroup.GetID());
			AddKnownSpell("Chirugy", "Cassius", specialInterruptGroup.GetID());
			
			var specialPurgeGroup:BarGroup = new BarGroup(BarGroup.GetNextID(m_groups), "Special Purges", Colours.PURPLE, true);
			m_groups.push(specialPurgeGroup);
			
			AddKnownSpell("Deathsquall", "", specialPurgeGroup.GetID());
			AddKnownSpell("Tide Wall", "", specialPurgeGroup.GetID());
			
			var specialOtherGroup:BarGroup = new BarGroup(BarGroup.GetNextID(m_groups), "Special Warnings", Colours.RED, true);
			m_groups.push(specialOtherGroup);
			
			AddKnownSpell("Deep Calling", "", specialOtherGroup.GetID());
			AddKnownSpell("Synapse Spasm", "", specialOtherGroup.GetID());
		}
	}
	
	private function AddKnownSpell(spellName:String, npc:String, group:String):Void
	{
		var id:String = KnownSpell.GetNextID(m_spells);
		m_spells[id] = new KnownSpell(id, spellName, npc, group);
	}
	
	private function SetDefaults():Void
	{
		m_defaults = new Object();
		m_defaults[Settings.X] = 650;
		m_defaults[Settings.Y] = 600;
		m_defaults[BIcon.ICON_X] = -1;
		m_defaults[BIcon.ICON_Y] = -1;
		Settings.SetBarX(m_defaults, Stage.width / 2 - 150);
		Settings.SetBarY(m_defaults, Stage.height / 5 * 3);
		Settings.SetBarWidth(m_defaults, 300);
		Settings.SetBarFontSize(m_defaults, 14);
	}
	
	private function SaveSettings():Void
	{
		/*if (m_configWindow != null)
		{
			var pt:Object = m_configWindow.GetCoords()
			m_settings[Settings.X] = pt.x;
			m_settings[Settings.Y] = pt.y;
		}*/
		
		var pt:Object = m_icon.GetCoords();
		m_settings[BIcon.ICON_X] = pt.x;
		m_settings[BIcon.ICON_Y] = pt.y;

		Settings.Save(SETTINGS_PREFIX, m_settings, m_defaults);
		SaveBarGroups();
		SaveKnownSpells();
	}

	private function SaveBarGroups():Void
	{
		var archive:Archive = Settings.GetArchive();
		var groupNumber:Number = 1;
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:BarGroup = m_groups[indx];
			if (thisGroup != null)
			{
				thisGroup.Save(archive, groupNumber);
				++groupNumber;
			}
		}
		
		for (var indx:Number = groupNumber; indx <= MAX_GROUPS; ++indx)
		{
			BarGroup.ClearArchive(archive, indx);
		}
	}
	
	private function LoadBarGroups():Void
	{
		m_groups = new Array();
		var archive:Archive = Settings.GetArchive();
		for (var indx:Number = 0; indx < MAX_GROUPS; ++indx)
		{
			var thisGroup:BarGroup = BarGroup.FromArchive(archive, indx + 1);
			if (thisGroup != null)
			{
				m_groups.push(thisGroup);
			}
		}
	}
	
	private function SaveKnownSpells():Void
	{
		var archive:Archive = Settings.GetArchive();
		var spellNumber:Number = 1;
		for (var indx in m_spells)
		{
			var thisSpell:KnownSpell = m_spells[indx];
			if (thisSpell != null)
			{
				thisSpell.Save(archive, spellNumber);
				++spellNumber;
			}
		}
		
		for (var indx:Number = spellNumber; indx <= MAX_SPELLS; ++indx)
		{
			KnownSpell.ClearArchive(archive, indx);
		}
	}
	
	private function LoadKnownSpells():Void
	{
		m_spells = new Object();
		var archive:Archive = Settings.GetArchive();
		for (var indx:Number = 0; indx < MAX_SPELLS; ++indx)
		{
			var thisSpell:KnownSpell = KnownSpell.FromArchive(archive, indx + 1);
			if (thisSpell != null)
			{
				m_spells[thisSpell.GetID()] = thisSpell;
			}
		}
	}
	
	private function RecreateCastbar():Void
	{
		if (m_castbar != null)
		{
			m_castbar.Unload();
		}
		
		m_castbar = new Castbar("", m_mc, Settings.GetBarX(m_settings), Settings.GetBarY(m_settings), Settings.GetBarWidth(m_settings), Settings.GetBarFontSize(m_settings), m_groups, m_spells);
	}
	
	private function ClearTarget():Void
	{
		if (m_target != null)
		{
			m_target.Unload();
			m_target = null;
		}
		
		if (m_castbar != null)
		{
			m_castbar.SetVisible(false);
		}				
	}
	
	private function ToggleConfigVisible():Void
	{
		if (m_configWindow == null)
		{
			m_optionsTab = new OptionsTab("Options", m_settings);
			m_spellTab = new SpellList("Spells", m_groups, m_spells, m_settings);
			m_configWindow = new TabWindow(m_mc, "BooBar", m_settings[Settings.X], m_settings[Settings.Y], 320, 200, Delegate.create(this, ConfigClosed), "BooBuildsHelp", "https://tswact.wordpress.com/boobar/");
			m_configWindow.AddTab("Spells", m_spellTab);
			m_configWindow.AddTab("Options", m_optionsTab);
			m_configWindow.SetVisible(true);
		}
		else
		{
			m_configWindow.SetVisible(!m_configWindow.GetVisible());
		}
		
		if (m_configWindow.GetVisible() != true)
		{
			ConfigClosed();
		}
	}
	
	private function ToggleDebugVisible():Void
	{
		DebugWindow.ToggleVisible();
	}
	
	private function ConfigClosed():Void
	{
		SaveSettings();
		RecreateCastbar();
	}	
	
	private function PlayerDied():Void
	{
		if (m_clientCharacter != null)
		{
			ClearTarget();
		}
	}
	
	private function TargetChanged(characterID:ID32):Void
	{
		if (characterID != null)
		{
			var character:Character = Character.GetCharacter(characterID);
			if (character != null)
			{
				ClearTarget();
				
				m_target = new Target(character, Delegate.create(this, CastbarUpdate));
			}
		}
	}
	
	private function CastbarUpdate(currentSpell:String, canInterrupt:Boolean, pct:Number):Void
	{
		if (m_target == null)
		{
			m_castbar.Update(currentSpell, "", canInterrupt, pct);
		}
		else
		{
			m_castbar.Update(currentSpell, m_target.GetName(), canInterrupt, pct);
		}
	}
}
