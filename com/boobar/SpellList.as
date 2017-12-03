import com.Utils.StringUtils;
import com.boobar.BarGroup;
import com.boobar.ChangeGroupDialog;
import com.boobar.EditGroupDialog;
import com.boobar.EditSpellDialog;
import com.boobar.KnownSpell;
import com.boobarcommon.Colours;
import com.boobarcommon.DebugWindow;
import com.boobarcommon.ITabPane;
import com.boobarcommon.InfoWindow;
import com.boobarcommon.OKDialog;
import com.boobarcommon.PopupMenu;
import com.boobarcommon.ScrollPane;
import com.boobarcommon.TreePanel;
import com.boobarcommon.YesNoDialog;
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
class com.boobar.SpellList implements ITabPane
{
	private var m_addonMC:MovieClip;
	private var m_parent:MovieClip;
	private var m_name:String;
	private var m_settings:Object;
	private var m_groups:Array;
	private var m_spells:Object;
	private var m_applySprint:Function;
	private var m_applyPet:Function;
	private var m_scrollPane:ScrollPane;
	private var m_spellTree:TreePanel;
	private var m_itemPopup:PopupMenu;
	private var m_groupPopup:PopupMenu;
	private var m_specialGroupPopup:PopupMenu;
	private var m_editSpellDialog:EditSpellDialog;
	private var m_editGroupDialog:EditGroupDialog;
	private var m_changeGroupDialog:ChangeGroupDialog;
	private var m_currentGroup:BarGroup;
	private var m_currentSpell:KnownSpell;
	private var m_yesNoDialog:YesNoDialog;
	private var m_okDialog:OKDialog;
	private var m_forceRedraw:Boolean;
	private var m_parentWidth:Number;
	private var m_parentHeight:Number;
	
	public function SpellList(name:String, groups:Array, spells:Object, settings:Object)
	{
		m_name = name;
		m_groups = groups;
		m_spells = spells;
		m_settings = settings;
		m_forceRedraw = false;
	}

	public function CreatePane(addonMC:MovieClip, parent:MovieClip, name:String, x:Number, y:Number, width:Number, height:Number):Void
	{
		m_parent = parent;
		m_name = name;
		m_addonMC = addonMC;
		m_parentWidth = parent._width;
		m_parentHeight = parent._height;
		m_scrollPane = new ScrollPane(m_parent, m_name + "Scroll", x, y, width, height, null, m_parentHeight * 0.1);
		
		m_itemPopup = new PopupMenu(m_addonMC, "ItemPopup", 6);
		m_itemPopup.AddItem("Edit", Delegate.create(this, EditSpell));
		m_itemPopup.AddItem("Change group", Delegate.create(this, ChangeGroup));
		m_itemPopup.AddSeparator();
		m_itemPopup.AddItem("Delete", Delegate.create(this, DeleteSpell));
		m_itemPopup.Rebuild();
		m_itemPopup.SetCoords(Stage.width / 2, Stage.height / 2);
		
		m_groupPopup = new PopupMenu(m_addonMC, "GroupPopup", 6);
		m_groupPopup.AddItem("Add Spell", Delegate.create(this, AddSpell));
		m_groupPopup.AddItem("Edit", Delegate.create(this, EditGroup));
		m_groupPopup.AddSeparator();
		m_groupPopup.AddItem("Add new group above", Delegate.create(this, AddGroupAbove));
		m_groupPopup.AddItem("Add new group below", Delegate.create(this, AddGroupBelow));
		m_groupPopup.AddSeparator();
		m_groupPopup.AddItem("Delete", Delegate.create(this, DeleteGroup));
		m_groupPopup.Rebuild();
		m_groupPopup.SetCoords(Stage.width / 2, Stage.height / 2);
		
		m_specialGroupPopup = new PopupMenu(m_addonMC, "SpecialGroupPopup", 6);
		m_specialGroupPopup.AddItem("Edit", Delegate.create(this, EditGroup));
		m_specialGroupPopup.Rebuild();
		m_specialGroupPopup.SetCoords(Stage.width / 2, Stage.height / 2);
		
		DrawList();
	}
	
	public function SetVisible(visible:Boolean):Void
	{
		m_scrollPane.SetVisible(visible);
		if (visible == true && m_forceRedraw == true)
		{
			m_forceRedraw = false;
			DrawList();
		}
	}
	
	public function GetVisible():Boolean
	{
		return m_scrollPane.GetVisible();
	}
	
	public function Save():Void
	{
		
	}
	
	public function StartDrag():Void
	{
		m_itemPopup.SetVisible(false);
		m_groupPopup.SetVisible(false);
	}
	
	public function StopDrag():Void
	{	
	}

	public function ForceRedraw():Void
	{
		m_forceRedraw = true;
	}

	public function DrawList():Void
	{
		var openSubMenus:Object = new Object();
		if (m_spellTree != null)
		{
			for (var indx:Number = 0; indx < m_spellTree.GetNumSubMenus(); ++indx)
			{
				if (m_spellTree.IsSubMenuOpen(indx))
				{
					openSubMenus[m_spellTree.GetSubMenuName(indx)] = true;
				}
			}
			
			m_spellTree.Unload();
		}
		
		var margin:Number = 3;
		var callback:Function = Delegate.create(this, function(a:TreePanel) { this.m_scrollPane.Resize(a.GetHeight()); } );
		m_spellTree = new TreePanel(m_scrollPane.GetMovieClip(), m_name + "Tree", margin, null, null, callback, Delegate.create(this, ContextMenu));
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:BarGroup = m_groups[indx];
			if (thisGroup != null)
			{
				//DebugWindow.Log(DebugWindow.Info, "Adding group " + thisGroup.GetName());
				var colours:Array = Colours.GetColourArray(thisGroup.GetColourName());
				var subTree:TreePanel = new TreePanel(m_spellTree.GetMovieClip(), "subTree" + thisGroup.GetName(), margin, colours[0], colours[1], callback, Delegate.create(this, ContextMenu));
				SpellSubMenu(subTree, thisGroup.GetID());
				m_spellTree.AddSubMenu(thisGroup.GetName(), thisGroup.GetID(), subTree, colours[0], colours[1]);
				//DebugWindow.Log(DebugWindow.Info, "Added group " + thisGroup.GetName());
			}
		}
		
		m_spellTree.Rebuild();
		m_spellTree.SetCoords(0, 0);
		
		m_scrollPane.SetContent(m_spellTree.GetMovieClip(), m_spellTree.GetHeight());
		
		for (var indx:Number = 0; indx < m_spellTree.GetNumSubMenus(); ++indx)
		{
			if (openSubMenus[m_spellTree.GetSubMenuName(indx)] == true)
			{
				m_spellTree.ToggleSubMenu(indx);
			}
		}
		
		m_spellTree.Layout();
		m_scrollPane.SetVisible(true);		
	}
	
	public function SpellSubMenu(subTree:TreePanel, groupID:String):Void
	{
		var sortedSpells:Array = KnownSpell.GetOrderedEntries(groupID, m_spells);
		for (var indx:Number = 0; indx < sortedSpells.length; ++indx)
		{
			var thisSpell:KnownSpell = sortedSpells[indx];
			if (thisSpell != null && thisSpell.GetGroup() == groupID)
			{
				subTree.AddItem(thisSpell.GetName(), null, String(thisSpell.GetID()));
			}
		}
	}
	
	private function ContextMenu(id:String, isGroup:Boolean):Void
	{
		if (isGroup != true)
		{
			if (m_groupPopup != null)
			{
				m_groupPopup.SetVisible(false);
			}
			
			if (m_specialGroupPopup != null)
			{
				m_specialGroupPopup.SetVisible(false);
			}
			
			if (m_itemPopup != null)
			{
				UnloadDialogs();
				m_itemPopup.SetUserData(id);
				m_itemPopup.SetCoords(_root._xmouse, _root._ymouse);
				m_itemPopup.SetVisible(true);
			}
		}
		else
		{
			if (m_itemPopup != null)
			{
				m_itemPopup.SetVisible(false);
			}

			if (id == BarGroup.INTERRUPT_GROUP || id == BarGroup.NO_INTERRUPT_GROUP)
			{
				if (m_groupPopup != null)
				{
					m_groupPopup.SetVisible(false);
				}
				
				if (m_specialGroupPopup != null)
				{
					UnloadDialogs();
					m_specialGroupPopup.SetUserData(id);
					m_specialGroupPopup.SetCoords(_root._xmouse, _root._ymouse);
					m_specialGroupPopup.SetVisible(true);
				}
			}
			else
			{
				if (m_specialGroupPopup != null)
				{
					m_specialGroupPopup.SetVisible(false);
				}
				
				if (m_groupPopup != null)
				{
					UnloadDialogs();
					m_groupPopup.SetUserData(id);
					m_groupPopup.SetCoords(_root._xmouse, _root._ymouse);
					m_groupPopup.SetVisible(true);
				}
			}
		}
	}

	public function UnloadDialogs():Void
	{
		if (m_yesNoDialog != null)
		{
			m_yesNoDialog.Unload();
			m_yesNoDialog = null;
		}
		
		if (m_okDialog != null)
		{
			m_okDialog.Unload();
			m_okDialog = null;
		}
		
		if (m_editSpellDialog != null)
		{
			m_editSpellDialog.Unload();
			m_editSpellDialog = null;
		}
		
		if (m_editGroupDialog != null)
		{
			m_editGroupDialog.Unload();
			m_editGroupDialog = null;
		}
		
		if (m_changeGroupDialog != null)
		{
			m_changeGroupDialog.Unload();
			m_changeGroupDialog = null;
		}
	}
	
	private function AddSpell(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			
			m_editSpellDialog = new EditSpellDialog("AddSpell", m_parent, m_parentWidth, m_parentHeight, "", "");
			m_editSpellDialog.Show(Delegate.create(this, AddSpellCB));
		}
	}
	
	private function AddSpellCB(newName:String, newNpcName:String):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "spell");
			if (nameValid == true && newName != "" && m_currentGroup != null)
			{
				var duplicateSpell:KnownSpell = KnownSpell.FindSpell(m_spells, newName, newNpcName);
				var duplicateFound:Boolean = duplicateSpell != null;					
				if (duplicateFound == false)
				{
					var spellID:String = KnownSpell.GetNextID(m_spells);
					var newSpell:KnownSpell = new KnownSpell(spellID, newName, newNpcName, m_currentGroup.GetID());
					m_spells[spellID] = newSpell;
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Add spell failed.  Spell already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function EditSpell(spellID:String):Void
	{
		m_currentSpell = m_spells[spellID];
		if (m_currentSpell != null)
		{
			UnloadDialogs();
			
			m_editSpellDialog = new EditSpellDialog("EditSpell", m_parent, m_parentWidth, m_parentHeight, m_currentSpell.GetName(), m_currentSpell.GetNPCName());
			m_editSpellDialog.Show(Delegate.create(this, EditSpellCB));
		}
	}
	
	private function EditSpellCB(newName:String, newNpcName:String):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "spell");
			if (nameValid == true && newName != "" && m_currentSpell != null)
			{
				if (m_currentSpell.GetName() != newName || m_currentSpell.GetNPCName() != newNpcName)
				{
					var duplicateSpell:KnownSpell = KnownSpell.FindSpell(m_spells, newName, newNpcName);
					var duplicateFound:Boolean = duplicateSpell != null;					
					if (duplicateFound == false)
					{
						m_currentSpell.SetName(newName);
						m_currentSpell.SetNPCName(newNpcName);
						DrawList();
					}
					else
					{
						InfoWindow.LogError("Update spell failed.  Spell already exists");				
					}
				}
			}
		}
		
		m_currentSpell = null;
	}
	
	private function DeleteSpell(spellID:String):Void
	{
		m_currentSpell = m_spells[spellID];
		if (m_currentSpell != null)
		{
			UnloadDialogs();
			
			m_spells[spellID] = null;
			DrawList();
		}
	}
	
	private function ChangeGroup(spellID:String):Void
	{
		m_currentSpell = m_spells[spellID];
		if (m_currentSpell != null)
		{
			m_currentGroup = FindGroupByID(m_currentSpell.GetGroup());
			if (m_currentGroup != null)
			{
				UnloadDialogs();
				
				m_changeGroupDialog = new ChangeGroupDialog("ChangeGroup", m_parent, m_addonMC, m_parentWidth, m_parentHeight, m_currentGroup.GetName(), m_groups);
				m_changeGroupDialog.Show(Delegate.create(this, ChangeGroupCB));
			}
		}
	}
	
	private function ChangeGroupCB(newName:String):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && newName != "" && m_currentSpell != null && m_currentGroup != null && newName != m_currentGroup.GetName())
			{
				var newGroup:BarGroup = null;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					if (m_groups[indx] != null && m_groups[indx].GetName() == newName)
					{
						newGroup = m_groups[indx];
						break;
					}
				}
				
				if (newGroup == null)
				{
					InfoWindow.LogError("Failed to find group " + newName);
				}
				else
				{
					m_currentSpell.SetGroup(newGroup.GetID());
					DrawList();
				}
			}
		}
		
		m_currentGroup = null;
		m_currentSpell = null;
	}
	
	private function DeleteGroup(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			if (m_groups.length > 1)
			{
				if (IsGroupEmpty(m_currentGroup) == true)
				{
					var thisGroup:BarGroup = null;
					var toDelete:Number = -1;
					for (var indx:Number = 0; indx < m_groups.length; ++indx)
					{
						thisGroup = m_groups[indx];
						if (thisGroup != null && thisGroup.GetID() == m_currentGroup.GetID())
						{
							toDelete = indx;
							break;
						}
					}
					
					if (toDelete != -1)
					{
						m_groups.splice(toDelete, 1);
						DrawList();
					}
				}
				else
				{
					m_okDialog = new OKDialog("DeleteGroup", m_parent, m_parentWidth, m_parentHeight, "You cannot delete a", "group with entries", "");
					m_okDialog.Show();
				}
			}
			else
			{
				m_okDialog = new OKDialog("DeleteGroup", m_parent, m_parentWidth, m_parentHeight, "You cannot delete the", "final group", "");
				m_okDialog.Show();
			}
		}
		
		m_currentGroup = null;
	}
	
	private function IsGroupEmpty(thisGroup:BarGroup):Boolean
	{
		for (var indx in m_spells)
		{
			var thisSpell:KnownSpell = m_spells[indx];
			if (thisSpell != null && thisSpell.GetGroup() == thisGroup.GetID())
			{
				return false;
			}
		}
		
		return true;
	}
	
	private function EditGroup(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			m_editGroupDialog = new EditGroupDialog("EditGroup", m_parent, m_parentWidth, m_parentHeight, m_currentGroup.GetName(), m_currentGroup.GetColourName(), m_currentGroup.GetScreenFlash(), m_currentGroup.GetHideBar());
			m_editGroupDialog.Show(Delegate.create(this, EditGroupCB));
		}
	}
	
	private function EditGroupCB(newName:String, newColour:String, screenFlash:Boolean, hideBar:Boolean):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && m_currentGroup != null && newColour != null)
			{
				var duplicateFound:Boolean = false;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					var tempGroup:BarGroup = m_groups[indx];
					if (tempGroup != null && tempGroup.GetID() != m_currentGroup.GetID() && tempGroup.GetName() == newName)
					{
						duplicateFound = true;
						break;
					}
				}

				if (duplicateFound == false)
				{
					m_currentGroup.SetName(newName);
					m_currentGroup.SetColourName(newColour);
					m_currentGroup.SetScreenFlash(screenFlash);
					m_currentGroup.SetHideBar(hideBar);
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Edit group failed.  Name already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function AddGroupAbove(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			m_editGroupDialog = new EditGroupDialog("AddGroupAbove", m_parent, m_parentWidth, m_parentHeight, "", Colours.GetDefaultColourName(), false, false);
			m_editGroupDialog.Show(Delegate.create(this, AddGroupAboveCB));
		}
	}
	
	private function AddGroupAboveCB(newName:String, newColour:String, screenFlash:Boolean, hideBar:Boolean):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && m_currentGroup != null)
			{
				var duplicateFound:Boolean = false;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					var tempGroup:BarGroup = m_groups[indx];
					if (tempGroup != null && tempGroup.GetName() == newName)
					{
						duplicateFound = true;
						break;
					}
				}

				if (duplicateFound == false)
				{
					var newID:String = BarGroup.GetNextID(m_groups);
					var newGroup:BarGroup = new BarGroup(newID, newName, newColour, screenFlash, hideBar);
					var indx:Number = BarGroup.GetGroupIndex(m_groups, m_currentGroup.GetID());
					m_groups.splice(indx, 0, newGroup);
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Add group failed.  Name already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function AddGroupBelow(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			m_editGroupDialog = new EditGroupDialog("AddGroupAbove", m_parent, m_parentWidth, m_parentHeight, "", Colours.GetDefaultColourName(), false, false);
			m_editGroupDialog.Show(Delegate.create(this, AddGroupBelowCB));
		}
	}
	
	private function AddGroupBelowCB(newName:String, newColour:String, screenFlash:Boolean, hideBar:Boolean):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && m_currentGroup != null)
			{
				var duplicateFound:Boolean = false;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					var tempGroup:BarGroup = m_groups[indx];
					if (tempGroup != null && tempGroup.GetName() == newName)
					{
						duplicateFound = true;
						break;
					}
				}

				if (duplicateFound == false)
				{
					var newID:String = BarGroup.GetNextID(m_groups);
					var newGroup:BarGroup = new BarGroup(newID, newName, newColour, screenFlash, hideBar);
					var indx:Number = BarGroup.GetGroupIndex(m_groups, m_currentGroup.GetID());
					m_groups.splice(indx + 1, 0, newGroup);
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Add group failed.  Name already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function FindGroupByID(groupID:String):BarGroup
	{
		var indx:Number = BarGroup.GetGroupIndex(m_groups, groupID);
		if (indx > -1)
		{
			return m_groups[indx];
		}
		
		return null;
	}
	
	private function IsValidName(newName:String, nameType:String):Boolean
	{
		var valid:Boolean = true;
		
		if (newName == null || StringUtils.Strip(newName) == "")
		{
			InfoWindow.LogError("Cannot have a blank " + nameType + " name");
			return false;
		}
		
		if (IsNameGotChar(newName, nameType, "%") == true)
		{
			valid = false;
		}
		if (IsNameGotChar(newName, nameType, "~") == true)
		{
			valid = false;
		}
		if (IsNameGotChar(newName, nameType, "|") == true)
		{
			valid = false;
		}
		
		return valid;
	}
	
	private function IsNameGotChar(newName:String, nameType:String, charType:String):Boolean
	{
		if (newName.indexOf(charType) != -1)
		{
			InfoWindow.LogError("Cannot have character " + charType + " in " + nameType + " names");
			return true;
		}
		
		return false;
	}
}