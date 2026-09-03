#!/usr/bin/env python3
import os
import hashlib

def gen_id(name):
    # Generates a deterministic 24-character hex ID
    h = hashlib.md5(name.encode('utf-8')).hexdigest().upper()
    return h[:24]

def main():
    base_dir = os.path.abspath(os.path.dirname(__file__))
    src_dir = os.path.join(base_dir, "SetGames")
    xcode_dir = os.path.join(base_dir, "SetGames.xcodeproj")
    os.makedirs(xcode_dir, exist_ok=True)

    # Collect all swift files
    swift_files = []
    for root, dirs, files in os.walk(src_dir):
        for f in files:
            if f.endswith(".swift"):
                rel_path = os.path.relpath(os.path.join(root, f), base_dir)
                swift_files.append(rel_path)
    swift_files.sort()

    assets_rel = "SetGames/Assets.xcassets"
    info_plist_rel = "SetGames/Info.plist"

    # IDs
    proj_id = gen_id("Project_SetGames")
    target_id = gen_id("Target_SetGames")
    main_group_id = gen_id("Group_Main")
    sources_phase_id = gen_id("Phase_Sources")
    resources_phase_id = gen_id("Phase_Resources")
    frameworks_phase_id = gen_id("Phase_Frameworks")

    proj_config_list_id = gen_id("ConfigList_Project")
    proj_debug_config_id = gen_id("Config_Project_Debug")
    proj_release_config_id = gen_id("Config_Project_Release")

    target_config_list_id = gen_id("ConfigList_Target")
    target_debug_config_id = gen_id("Config_Target_Debug")
    target_release_config_id = gen_id("Config_Target_Release")

    app_product_ref_id = gen_id("Product_SetGamesApp")
    products_group_id = gen_id("Group_Products")

    assets_file_ref_id = gen_id("FileRef_" + assets_rel)
    assets_build_file_id = gen_id("BuildFile_" + assets_rel)
    info_plist_ref_id = gen_id("FileRef_" + info_plist_rel)
    
    google_plist_rel = "SetGames/GoogleService-Info.plist"
    google_plist_file_ref_id = gen_id("FileRef_" + google_plist_rel)
    google_plist_build_file_id = gen_id("BuildFile_" + google_plist_rel)

    # Build files & file refs for swift files
    swift_refs = []
    for sf in swift_files:
        fname = os.path.basename(sf)
        file_ref = gen_id("FileRef_" + sf)
        build_file = gen_id("BuildFile_" + sf)
        swift_refs.append({
            "path": sf,
            "filename": fname,
            "file_ref": file_ref,
            "build_file": build_file
        })

    # Hierarchical groups in SetGames
    # We will build sub-groups based on directory structure
    groups = {}
    
    # helper to get or create group id
    def get_group_id(rel_dir):
        if rel_dir == "":
            return main_group_id
        return gen_id("GroupDir_" + rel_dir)

    all_dirs = set()
    for item in swift_refs:
        d = os.path.dirname(item["path"])
        while d and d != "SetGames":
            all_dirs.add(d)
            d = os.path.dirname(d)
        all_dirs.add("SetGames")

    pbx = []
    pbx.append("// !$*UTF8*$!")
    pbx.append("{")
    pbx.append("\tarchiveVersion = 1;")
    pbx.append("\tclasses = {")
    pbx.append("\t};")
    pbx.append("\tobjectVersion = 56;")
    pbx.append("\tobjects = {")

    # PBXBuildFile
    pbx.append("/* Begin PBXBuildFile section */")
    pbx.append(f"\t\t{assets_build_file_id} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {assets_file_ref_id} /* Assets.xcassets */; }};")
    pbx.append(f"\t\t{google_plist_build_file_id} /* GoogleService-Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {google_plist_file_ref_id} /* GoogleService-Info.plist */; }};")
    for item in swift_refs:
        pbx.append(f"\t\t{item['build_file']} /* {item['filename']} in Sources */ = {{isa = PBXBuildFile; fileRef = {item['file_ref']} /* {item['filename']} */; }};")
    pbx.append("/* End PBXBuildFile section */\n")

    # PBXFileReference
    pbx.append("/* Begin PBXFileReference section */")
    pbx.append(f"\t\t{app_product_ref_id} /* SetGames.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = SetGames.app; sourceTree = BUILT_PRODUCTS_DIR; }};")
    pbx.append(f"\t\t{assets_file_ref_id} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = \"<group>\"; }};")
    pbx.append(f"\t\t{info_plist_ref_id} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; }};")
    pbx.append(f"\t\t{google_plist_file_ref_id} /* GoogleService-Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = GoogleService-Info.plist; sourceTree = \"<group>\"; }};")
    for item in swift_refs:
        pbx.append(f"\t\t{item['file_ref']} /* {item['filename']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"{os.path.basename(item['path'])}\"; sourceTree = \"<group>\"; }};")
    pbx.append("/* End PBXFileReference section */\n")

    # PBXFrameworksBuildPhase
    pbx.append("/* Begin PBXFrameworksBuildPhase section */")
    pbx.append(f"\t\t{frameworks_phase_id} /* Frameworks */ = {{")
    pbx.append("\t\t\tisa = PBXFrameworksBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXFrameworksBuildPhase section */\n")

    # PBXGroup section
    pbx.append("/* Begin PBXGroup section */")
    
    # Build tree
    dir_children = {} # dir -> list of (is_dir, name, id)
    for d in all_dirs:
        dir_children[d] = []
    dir_children[""] = [ (True, "SetGames", get_group_id("SetGames")), (True, "Products", products_group_id) ]

    # Add subdirectories
    for d in sorted(all_dirs):
        parent = os.path.dirname(d)
        if parent in dir_children:
            dir_children[parent].append((True, os.path.basename(d), get_group_id(d)))

    # Add swift files into their respective directory
    for item in swift_refs:
        parent = os.path.dirname(item["path"])
        if parent in dir_children:
            dir_children[parent].append((False, item["filename"], item["file_ref"]))

    # Add Assets, Info.plist, and GoogleService-Info.plist to SetGames group
    dir_children["SetGames"].append((False, "Assets.xcassets", assets_file_ref_id))
    dir_children["SetGames"].append((False, "Info.plist", info_plist_ref_id))
    dir_children["SetGames"].append((False, "GoogleService-Info.plist", google_plist_file_ref_id))

    # Main group
    pbx.append(f"\t\t{main_group_id} = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{get_group_id('SetGames')} /* SetGames */,")
    pbx.append(f"\t\t\t\t{products_group_id} /* Products */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    # Products group
    pbx.append(f"\t\t{products_group_id} /* Products */ = {{")
    pbx.append("\t\t\tisa = PBXGroup;")
    pbx.append("\t\t\tchildren = (")
    pbx.append(f"\t\t\t\t{app_product_ref_id} /* SetGames.app */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = Products;")
    pbx.append("\t\t\tsourceTree = \"<group>\";")
    pbx.append("\t\t};")

    # Each sub-dir group
    for d in sorted(all_dirs):
        gid = get_group_id(d)
        dname = os.path.basename(d) if d != "SetGames" else "SetGames"
        pbx.append(f"\t\t{gid} /* {dname} */ = {{")
        pbx.append("\t\t\tisa = PBXGroup;")
        pbx.append("\t\t\tchildren = (")
        # eliminate duplicate entries
        seen = set()
        for is_d, name, cid in dir_children.get(d, []):
            if cid not in seen:
                seen.add(cid)
                pbx.append(f"\t\t\t\t{cid} /* {name} */,")
        pbx.append("\t\t\t);")
        pbx.append(f"\t\t\tpath = \"{dname}\";")
        pbx.append("\t\t\tsourceTree = \"<group>\";")
        pbx.append("\t\t};")

    pbx.append("/* End PBXGroup section */\n")

    # PBXNativeTarget
    pbx.append("/* Begin PBXNativeTarget section */")
    pbx.append(f"\t\t{target_id} /* SetGames */ = {{")
    pbx.append("\t\t\tisa = PBXNativeTarget;")
    pbx.append(f"\t\t\tbuildConfigurationList = {target_config_list_id} /* Build configuration list for PBXNativeTarget \"SetGames\" */;")
    pbx.append("\t\t\tbuildPhases = (")
    pbx.append(f"\t\t\t\t{sources_phase_id} /* Sources */,")
    pbx.append(f"\t\t\t\t{frameworks_phase_id} /* Frameworks */,")
    pbx.append(f"\t\t\t\t{resources_phase_id} /* Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tbuildRules = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdependencies = (")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tname = SetGames;")
    pbx.append("\t\t\tproductName = SetGames;")
    pbx.append(f"\t\t\tproductReference = {app_product_ref_id} /* SetGames.app */;")
    pbx.append("\t\t\tproductType = \"com.apple.product-type.application\";")
    pbx.append("\t\t};")
    pbx.append("/* End PBXNativeTarget section */\n")

    # PBXProject
    pbx.append("/* Begin PBXProject section */")
    pbx.append(f"\t\t{proj_id} /* Project object */ = {{")
    pbx.append("\t\t\tisa = PBXProject;")
    pbx.append("\t\t\tattributes = {")
    pbx.append("\t\t\t\tBuildIndependentTargetsInParallel = 1;")
    pbx.append("\t\t\t\tLastUpgradeCheck = 1600;")
    pbx.append("\t\t\t\tTargetAttributes = {")
    pbx.append(f"\t\t\t\t\t{target_id} = {{")
    pbx.append("\t\t\t\t\t\tCreatedOnToolsVersion = 16.0;")
    pbx.append("\t\t\t\t\t\tDevelopmentTeam = N3DW2PW8GA;")
    pbx.append("\t\t\t\t\t\tProvisioningStyle = Automatic;")
    pbx.append("\t\t\t\t\t};")
    pbx.append("\t\t\t\t};")
    pbx.append("\t\t\t};")
    pbx.append(f"\t\t\tbuildConfigurationList = {proj_config_list_id} /* Build configuration list for PBXProject \"SetGames\" */;")
    pbx.append("\t\t\tcompatibilityVersion = \"Xcode 14.0\";")
    pbx.append("\t\t\tdevelopmentRegion = en;")
    pbx.append("\t\t\thasScannedForEncodings = 0;")
    pbx.append("\t\t\tknownRegions = (")
    pbx.append("\t\t\t\ten,")
    pbx.append("\t\t\t\tBase,")
    pbx.append("\t\t\t);")
    pbx.append(f"\t\t\tmainGroup = {main_group_id};")
    pbx.append(f"\t\t\tproductRefGroup = {products_group_id} /* Products */;")
    pbx.append("\t\t\tprojectDirPath = \"\";")
    pbx.append("\t\t\tprojectRoot = \"\";")
    pbx.append("\t\t\ttargets = (")
    pbx.append(f"\t\t\t\t{target_id} /* SetGames */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t};")
    pbx.append("/* End PBXProject section */\n")

    # PBXResourcesBuildPhase
    pbx.append("/* Begin PBXResourcesBuildPhase section */")
    pbx.append(f"\t\t{resources_phase_id} /* Resources */ = {{")
    pbx.append("\t\t\tisa = PBXResourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    pbx.append(f"\t\t\t\t{assets_build_file_id} /* Assets.xcassets in Resources */,")
    pbx.append(f"\t\t\t\t{google_plist_build_file_id} /* GoogleService-Info.plist in Resources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXResourcesBuildPhase section */\n")

    # PBXSourcesBuildPhase
    pbx.append("/* Begin PBXSourcesBuildPhase section */")
    pbx.append(f"\t\t{sources_phase_id} /* Sources */ = {{")
    pbx.append("\t\t\tisa = PBXSourcesBuildPhase;")
    pbx.append("\t\t\tbuildActionMask = 2147483647;")
    pbx.append("\t\t\tfiles = (")
    for item in swift_refs:
        pbx.append(f"\t\t\t\t{item['build_file']} /* {item['filename']} in Sources */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\trunOnlyForDeploymentPostprocessing = 0;")
    pbx.append("\t\t};")
    pbx.append("/* End PBXSourcesBuildPhase section */\n")

    # XCBuildConfiguration
    pbx.append("/* Begin XCBuildConfiguration section */")
    # Proj Debug
    pbx.append(f"\t\t{proj_debug_config_id} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;")
    pbx.append("\t\t\t\tENABLE_TESTABILITY = YES;")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;")
    pbx.append("\t\t\t\tONLY_ACTIVE_ARCH = YES;")
    pbx.append("\t\t\t\tSDKROOT = iphoneos;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-Onone\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    # Proj Release
    pbx.append(f"\t\t{proj_release_config_id} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;")
    pbx.append("\t\t\t\tCLANG_ENABLE_MODULES = YES;")
    pbx.append("\t\t\t\tDEBUG_INFORMATION_FORMAT = \"dwarf-with-dsym\";")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append("\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;")
    pbx.append("\t\t\t\tSDKROOT = iphoneos;")
    pbx.append("\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = \"-O\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")

    # Target Debug
    pbx.append(f"\t\t{target_debug_config_id} /* Debug */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
    pbx.append("\t\t\t\tCODE_SIGN_IDENTITY = \"Apple Development\";")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append("\t\t\t\tDEVELOPMENT_TEAM = N3DW2PW8GA;")
    pbx.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    pbx.append("\t\t\t\tINFOPLIST_FILE = SetGames/Info.plist;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UIRequiresFullScreen = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = \"UIInterfaceOrientationPortrait\";")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks\";")
    pbx.append("\t\t\t\tMARKETING_VERSION = 1.0;")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.peterthach.SetGames;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Debug;")
    pbx.append("\t\t};")

    # Target Release
    pbx.append(f"\t\t{target_release_config_id} /* Release */ = {{")
    pbx.append("\t\t\tisa = XCBuildConfiguration;")
    pbx.append("\t\t\tbuildSettings = {")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;")
    pbx.append("\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;")
    pbx.append("\t\t\t\tCODE_SIGN_IDENTITY = \"Apple Development\";")
    pbx.append("\t\t\t\tCODE_SIGN_STYLE = Automatic;")
    pbx.append("\t\t\t\tDEVELOPMENT_TEAM = N3DW2PW8GA;")
    pbx.append("\t\t\t\tCURRENT_PROJECT_VERSION = 1;")
    pbx.append("\t\t\t\tGENERATE_INFOPLIST_FILE = NO;")
    pbx.append("\t\t\t\tINFOPLIST_FILE = SetGames/Info.plist;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UIRequiresFullScreen = YES;")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPad = \"UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight\";")
    pbx.append("\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = \"UIInterfaceOrientationPortrait\";")
    pbx.append("\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;")
    pbx.append("\t\t\t\tLD_RUNPATH_SEARCH_PATHS = \"$(inherited) @executable_path/Frameworks\";")
    pbx.append("\t\t\t\tMARKETING_VERSION = 1.0;")
    pbx.append("\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.peterthach.SetGames;")
    pbx.append("\t\t\t\tPRODUCT_NAME = \"$(TARGET_NAME)\";")
    pbx.append("\t\t\t\tSWIFT_VERSION = 5.0;")
    pbx.append("\t\t\t\tTARGETED_DEVICE_FAMILY = \"1,2\";")
    pbx.append("\t\t\t};")
    pbx.append("\t\t\tname = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCBuildConfiguration section */\n")

    # XCConfigurationList
    pbx.append("/* Begin XCConfigurationList section */")
    pbx.append(f"\t\t{proj_config_list_id} /* Build configuration list for PBXProject \"SetGames\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{proj_debug_config_id} /* Debug */,")
    pbx.append(f"\t\t\t\t{proj_release_config_id} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Release;")
    pbx.append("\t\t};")

    pbx.append(f"\t\t{target_config_list_id} /* Build configuration list for PBXNativeTarget \"SetGames\" */ = {{")
    pbx.append("\t\t\tisa = XCConfigurationList;")
    pbx.append("\t\t\tbuildConfigurations = (")
    pbx.append(f"\t\t\t\t{target_debug_config_id} /* Debug */,")
    pbx.append(f"\t\t\t\t{target_release_config_id} /* Release */,")
    pbx.append("\t\t\t);")
    pbx.append("\t\t\tdefaultConfigurationIsVisible = 0;")
    pbx.append("\t\t\tdefaultConfigurationName = Release;")
    pbx.append("\t\t};")
    pbx.append("/* End XCConfigurationList section */\n")

    pbx.append("\t};")
    pbx.append(f"\trootObject = {proj_id} /* Project object */;")
    pbx.append("}")

    pbx_path = os.path.join(xcode_dir, "project.pbxproj")
    with open(pbx_path, "w", encoding="utf-8") as f:
        f.write("\n".join(pbx))
    print(f"Generated {pbx_path} with {len(swift_files)} Swift source files.")

if __name__ == "__main__":
    main()
