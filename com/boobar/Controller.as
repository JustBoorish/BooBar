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
import com.boobarcommon.Colours;
import com.boobarcommon.DebugWindow;
import com.boobarcommon.TabWindow;
import com.boobar.BarGroup;
import com.boobar.BIcon;
import com.boobar.Controller;
import com.boobar.KnownSpell;
import com.boobar.Settings;
import mx.utils.Delegate;
import com.boobarcommon.Proxy;
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
	private static var VERSION:String = "1.1";
	private static var SETTINGS_PREFIX:String = "BOOBAR";
	private static var MAX_GROUPS:Number = 75;
	private static var MAX_SPELLS:Number = 250;
	private static var MAX_TARGETS:Number = 3;

	private static var m_instance:Controller = null;
	
	private var m_debug:DebugWindow = null;
	private var m_icon:BIcon;
	private var m_mc:MovieClip;
	private var m_defaults:Object;
	private var m_settings:Object;
	private var m_clientCharacter:Character;
	private var m_characterName:String;
	private var m_targets:Array;
	private var m_castbars:Array;
	private var m_groups:Array;
	private var m_spells:Object;
	private var m_configWindow:TabWindow;
	private var m_optionsTab:OptionsTab;
	private var m_spellTab:SpellList;
	private var m_specialMobs:Object;
	
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
				m_debug = DebugWindow.GetInstance(m_mc, DebugWindow.Debug, "BooBarDebug");
			}
		}
		DebugWindow.Log(DebugWindow.Info, "BooBar Loaded");

		_root["boobar\\boobar"].OnModuleActivated = Delegate.create(this, OnModuleActivated);
		_root["boobar\\boobar"].OnModuleDeactivated = Delegate.create(this, OnModuleDeactivated);
		
		m_mc._x = 0;
		m_mc._y = 0;
		m_characterName = null;
		m_targets = new Array();
		m_castbars = new Array();
		for (var indx:Number = 0; indx < MAX_TARGETS; ++indx)
		{
			m_targets.push(null);
			m_castbars.push(null);
		}
		
		SetDefaults();
	}
	
	function OnModuleActivated(config:Archive):Void
	{
		Settings.SetArchive(config);
		DebugWindow.Log("BooBar OnModuleActivated "); // + config.toString());
		
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
			
			RecreateCastbars();
			
			m_icon = new BIcon(m_mc, _root["boobar\\boobar"].BooBarIcon, VERSION, Delegate.create(this, ToggleConfigVisible), null, null, Delegate.create(this, ToggleDebugVisible), m_settings[BIcon.ICON_X], m_settings[BIcon.ICON_Y]);
		}
		
		HideCastbars();
	}
	
	function OnModuleDeactivated():Archive
	{		
		SaveSettings();
		ClearTargets();

		var ret:Archive = Settings.GetArchive();
		//DebugWindow.Log("BooBar OnModuleDeactivated: " + ret.toString());
		return ret;
	}
	
	private function SetDefaultSpells():Void
	{
		if (m_groups.length == 0)
		{
			m_groups.push(new BarGroup(BarGroup.GetNextID(m_groups), "Uninterruptable", Colours.GREY, false));
			m_groups.push(new BarGroup(BarGroup.GetNextID(m_groups), "Interruptable", Colours.AQUA, false));
			
			m_spells = new Object();
			var specialInterruptGroup:BarGroup = new BarGroup(BarGroup.GetNextID(m_groups), "Special Interrupts", Colours.YELLOW, true);
			m_groups.push(specialInterruptGroup);
			
			AddKnownSpell("Charged Hack", "", specialInterruptGroup.GetID());
			AddKnownSpell("Mjolnir's Echo", "", specialInterruptGroup.GetID());
			AddKnownSpell("Searing Brand", "", specialInterruptGroup.GetID());
			AddKnownSpell("Itzama's Wrath", "", specialInterruptGroup.GetID());
			AddKnownSpell("Rot Iron", "", specialInterruptGroup.GetID());
			AddKnownSpell("Painwheel Overdrive", "", specialInterruptGroup.GetID());
			AddKnownSpell("Demolish", "", specialInterruptGroup.GetID());
			AddKnownSpell("Chirurgy", "Cassius, Hadean Guard", specialInterruptGroup.GetID());
			AddKnownSpell("Concuss", "", specialInterruptGroup.GetID());
			
			var specialPurgeGroup:BarGroup = new BarGroup(BarGroup.GetNextID(m_groups), "Special Purges", Colours.PURPLE, true);
			m_groups.push(specialPurgeGroup);
			
			AddKnownSpell("Deathsquall", "", specialPurgeGroup.GetID());
			AddKnownSpell("Tide Wall", "", specialPurgeGroup.GetID());
			
			var specialOtherGroup:BarGroup = new BarGroup(BarGroup.GetNextID(m_groups), "Special Warnings", Colours.RED, true);
			m_groups.push(specialOtherGroup);
			
			AddKnownSpell("Deep Calling", "", specialOtherGroup.GetID());
			AddKnownSpell("Drink Deep", "", specialOtherGroup.GetID());
			AddKnownSpell("Molten Metal", "", specialOtherGroup.GetID());
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
		
		for (var indx:Number = 0; indx < MAX_TARGETS; ++indx)
		{
			if (indx == 0)
			{
				Settings.SetBarX(m_defaults, indx, Stage.width / 2 - 150);
				Settings.SetBarY(m_defaults, indx, Stage.height / 5 * 3);
			}
			else
			{
				Settings.SetBarX(m_defaults, indx, Stage.width / 4 * 3);
				Settings.SetBarY(m_defaults, indx, Stage.height / 5 + (indx * 30));
			}
			
			Settings.SetBarWidth(m_defaults, indx, 300);
			Settings.SetBarFontSize(m_defaults, indx, 14);
		}
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
	
	private function RecreateCastbars():Void
	{
		for (var indx:Number = 0; indx < m_castbars.length; ++indx)
		{
			if (m_castbars[indx] != null)
			{
				m_castbars[indx].Unload();
			}
			
			var showNpcName:Boolean = true;
			if (indx == 0)
			{
				showNpcName = false;
			}
			
			m_castbars[indx] = new Castbar("Castbar" + indx, m_mc, Settings.GetBarX(m_settings, indx), Settings.GetBarY(m_settings, indx), Settings.GetBarWidth(m_settings, indx), Settings.GetBarFontSize(m_settings, indx), showNpcName, m_groups, m_spells);
		}
	}
	
	private function HideCastbars():Void
	{
		for (var indx:Number = 0; indx < m_castbars.length; ++indx)
		{
			if (m_castbars[indx] != null)
			{
				m_castbars[indx].SetVisible(false);
			}
		}
	}
	
	private function ClearTargets():Void
	{
		for (var indx:Number = 0; indx < m_targets.length; ++indx)
		{
			ClearTarget(indx);
		}
	}
	
	private function ClearTarget(indx:Number):Void
	{
		if (m_targets[indx] != null)
		{
			m_targets[indx].Unload();
			m_targets[indx] = null;
		}
		
		HideCastbar(indx);
	}
	
	private function ToggleConfigVisible():Void
	{
		if (m_configWindow == null)
		{
			m_optionsTab = new OptionsTab("Options", m_settings);
			m_spellTab = new SpellList("Spells", m_groups, m_spells, m_settings);
			m_configWindow = new TabWindow(m_mc, "BooBar", m_settings[Settings.X], m_settings[Settings.Y], 320, 200, Delegate.create(this, ConfigClosed), "BooBarHelp", "https://tswact.wordpress.com/boobar/");
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
		RecreateCastbars();
	}	
	
	private function PlayerDied():Void
	{
		if (m_clientCharacter != null)
		{
			ClearTargets();
		}
	}
	
	private function TargetChanged(characterID:ID32):Void
	{
		if (characterID != null)
		{
			if (m_targets[0] == null || !m_targets[0].ID32Matches(characterID))
			{
				var character:Character = Character.GetCharacter(characterID);
				if (character != null)
				{
					DemoteTarget(characterID);
					
					ClearTarget(0);
					m_targets[0] = new Target(character, Proxy.createThreeArgs(this, CastbarUpdate, 0));
				}
			}
		}
	}
	
	private function CastbarUpdate(currentSpell:String, canInterrupt:Boolean, pct:Number, targetNumber:Number):Void
	{
		if (m_targets[targetNumber] == null)
		{
			if (m_castbars[targetNumber] != null)
			{
				m_castbars[targetNumber].Update(currentSpell, "", canInterrupt, pct);
			}
		}
		else
		{
			if (m_castbars[targetNumber] != null)
			{
				m_castbars[targetNumber].Update(currentSpell, m_targets[targetNumber].GetName(), canInterrupt, pct);
			}
		}
	}
	
	private function HideCastbar(indx:Number):Void
	{
		if (m_castbars[indx] != null)
		{
			m_castbars[indx].SetVisible(false);
		}				
	}
	
	private function IsSpecialMob(target:Target):Boolean
	{
		return false;
		
		/*
		if (m_specialMobs == null)
		{
			m_specialMobs = new Object();
			m_specialMobs["Orochi Dead Ops"] = 1;
			m_specialMobs["The Ur-Draug"] = 1;
			m_specialMobs["Brutus, Hadean Guard"] = 1;
			m_specialMobs["Cassius, Hadean Guard"] = 1;
			m_specialMobs["The Iscariot, Hadean Guard"] = 1;
			m_specialMobs["Prime Maker"] = 1;
		}
		
		var ret:Boolean = false;
		if (target.GetName() != null)
		{
			if (m_specialMobs[target.GetName()] == 1)
			{
				DebugWindow.Log(DebugWindow.Debug, "Special mob " + target.GetName());
				ret = true;
			}
		}
		
		return ret;
		*/
	}
	
	private function DemoteTarget(characterID:ID32):Void
	{
		var newTargets:Array = new Array();
		for (var indx:Number = 0; indx < m_targets.length; ++indx)
		{
			newTargets.push(null);
			
			if (m_targets[indx] != null && m_targets[indx].ID32Matches(characterID))
			{
				ClearTarget(indx);
			}
		}
		
		for (var indx:Number = 0; indx < m_targets.length - 1; ++indx)
		{
			if (m_targets[indx] != null)
			{
				if (IsSpecialMob(m_targets[indx]))
				{
					newTargets[indx + 1] = m_targets[indx];
					newTargets[indx + 1].SetUpdateFunction(Proxy.createThreeArgs(this, CastbarUpdate, indx + 1));
				}
				else
				{
					ClearTarget(indx);
				}
			}
		}
		
		if (m_targets[m_targets.length - 1] != null)
		{
			ClearTarget(m_targets.length - 1);
		}
		
		m_targets = newTargets;
	}
}
