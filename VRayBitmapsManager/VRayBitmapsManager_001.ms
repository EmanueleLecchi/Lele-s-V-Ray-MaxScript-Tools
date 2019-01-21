
(
	global VrayBitmapManager_Roll
	try(destroyDialog VrayBitmapManager_Roll)catch()	
	
	rollout VrayBitmapManager_Roll "V-Ray Bitmaps Manager" width:280 height:296
	(
		fn initListView lv =
		(
			lv.gridLines = true
			--The following controls the display of details. We use defaults:
			lv.View = (dotNetClass "System.Windows.Forms.View").Details
			lv.fullRowSelect = true
			lv.allowColumnReorder=true
-- 			lv.CheckBoxes = true
-- 			lv.Sorting = (dotNetClass "System.Windows.Forms.SortOrder").ascending
			lv.width=512
			layout_def = #("Loader Type","FileName", "Path", "Gamma", "Format")
-- 			lv.backColor=lv.backColor.FromArgb 220 220 220
			lv.hideSelection=false
			for i in layout_def do
			lv.Columns.add i 128 
			)

		fn fillInSpreadSheet lv =
		(
			theRange = #() --array to collect the list items
			theBitmaps=getClassInstances BitmapTexture
			theVRayHDRIMaps=getClassInstances vrayHdri
			
			for o in theBitmaps do
			(
				--First we create a ListViewItem objectwith the object's name:
				li = dotNetObject "System.Windows.Forms.ListViewItem" "BitmapTexture"
				--Then we add all the sub-itemswith the desired string values:				
				sub_li = li.SubItems.add o.name
				sub_li = li.SubItems.add (o.fileName)
				sub_li = li.SubItems.add (try((o.bitmap.gamma) as string)catch("--"))
				sub_li = li.SubItems.add (try(getFileNameType o.filename)catch("--"))
				append theRange li--we add the list item to the array
			)
			for o in theVRayHDRIMaps do
			(
				--First we create a ListViewItem objectwith the object's name:
				li = dotNetObject "System.Windows.Forms.ListViewItem" "VRayHDRI"
				--Then we add all the sub-itemswith the desired string values:				
				sub_li = li.SubItems.add o.name
				sub_li = li.SubItems.add (o.hdrimapname)
				theGamma="--"
				case of
				(
					(o.color_space==0):(theGamma="1.0")
					(o.color_space==1 or o.color_space==2):(theGamma=(1.0/o.gamma) as string)
					(o.color_space==3):(theGamma=fileInGamma as string)
				)
				sub_li = li.SubItems.add theGamma
				sub_li = li.SubItems.add (try(getFileNameType o.hdrimapname)catch("--"))
				append theRange li--we add the list item to the array
			)			
			
			lv.Items.AddRange theRange--when done, we populate the ListView
			
		)
		
		fn selectListItmes lv mode=
		(
			case of
			(
				(mode == "all"):
				(
					for i=1 to lv.Items.count-1 do
					(
						lv.Items.item[i].selected = on
					)
				)
				(mode == "toggle"):
				(
					for i=1 to lv.Items.count-1 do
					(
						lv.Items.item[i].selected = not lv.Items.item[i].selected
					)
				)			
				(mode == "none"):
				(
					for i=1 to lv.Items.count-1 do
					(
						lv.Items.item[i].selected = off
					)
				)				
			)
			
			SetFocus VrayBitmapManager_Roll.lv_maps
		)
		
		
		GroupBOX 'grp1' "Selection Controls" pos:[8,8] width:280 height:40
		button 'btn1' "Select All" pos:[16,24] width:80 height:16 align:#left
		button 'btn2' "Select None" pos:[104,24] width:80 height:16 align:#left
		button 'btn3' "Select Toggle" pos:[192,24] width:80 height:16 align:#left
		GroupBOX 'grp2' "Conversion Controls" pos:[8,56] width:280 height:80

		checkbutton 'ckb1' "Convert to VRayHDRI" pos:[16,72] width:128 height:16 align:#left
		checkbutton 'ckb2' "All" pos:[154,72] width:128 height:16 align:#left
		button 'btnGo' "Go!" pos:[16,96] width:266 height:32
		dotNetControl 'lv_maps' "System.Windows.Forms.ListView" pos:[8,144] width:256 height:256 align:#left
		
		
		on VrayBitmapManager_Roll open do
		(
			initListView lv_maps
			fillInSpreadSheet lv_maps
-- 			lv_maps.pos=[8,64]
			lv_maps.width=(VrayBitmapManager_Roll.width-16) 
			lv_maps.height=(VrayBitmapManager_Roll.height-152)
			for c=0 to 3 do
			(
				lv_maps.AutoResizeColumn c (dotNetClass "ColumnHeaderAutoResizeStyle").ColumnContent
			)
			lv_maps.AutoResizeColumn 4 (dotNetClass "ColumnHeaderAutoResizeStyle").headerSize
		)
		on VrayBitmapManager_Roll resized size do
		(
			lv_maps.width=(size[1]-16) 
			lv_maps.height=(size[2]-88)
		)
		
		on ckb1 changed state do
		(
			ckb1.text=if state then "Convert to Tiled" else "Convert to VRayHDRI"
		)
		on ckb2 changed state do
		(
			ckb2.text=if state then "Selected" else "All"
		)
		on btn1 pressed do
		(
			selectListItmes lv_maps "all"
		)
		on btn2 pressed do
		(
			selectListItmes lv_maps "none"
		)
		on btn3 pressed do
		(
			selectListItmes lv_maps "toggle"
		)
		on btnGo pressed do 
		(
			
		)
		
	)

	createDialog VrayBitmapManager_Roll 800 600 style:#(#style_titlebar, #style_border, #style_sysmenu,#style_resizing,#style_minimizebox,#style_maximizebox) 
)
