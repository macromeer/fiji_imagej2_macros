// Fiji macro: Batch crop XYCZT TIFFs - interactive ROI per file

// Ask user for input directory
inputDir = getDirectory("Choose the folder containing TIFF files");
if (inputDir == "") exit("No folder selected. Exiting.");

// Get list of TIFF files
list = getFileList(inputDir);
tiffFiles = newArray();
for (i = 0; i < list.length; i++) {
    if (endsWith(list[i], ".tif") || endsWith(list[i], ".tiff")) {
        tiffFiles = Array.concat(tiffFiles, list[i]);
    }
}

if (tiffFiles.length == 0) exit("No TIFF files found.");

print("Found " + tiffFiles.length + " TIFF file(s) to process.");

// Process each file
for (i = 0; i < tiffFiles.length; i++) {
    
    // Open image in interactive mode
    setBatchMode(false);
    open(inputDir + tiffFiles[i]);
    originalID = getImageID();
    title = getTitle();
    
    // Get dimensions
    getDimensions(width, height, channels, slices, frames);
    print("\n[" + (i+1) + "/" + tiffFiles.length + "] Processing: " + title);
    print("Dimensions: C=" + channels + ", Z=" + slices + ", T=" + frames);
    
    // Clear ROI Manager before asking for new ROIs
    roiManager("reset");
    
    // Let user draw ROI(s) for THIS image
    setTool("rectangle");
    waitForUser("Draw ROI(s) for: " + title, 
        "Image " + (i+1) + " of " + tiffFiles.length + "\n \n" +
        "Draw (rectangle!) one or multiple ROIs:\n \n" +
        "For multiple ROIs:\n" +
        "1. Draw first ROI\n" +
        "2. Press 't' to add to ROI Manager\n" +
        "3. Repeat for each ROI\n \n" +
        "For single ROI:\n" +
        "Just draw the ROI\n \n" +
        "Click OK when finished.");
    
    // Check if user added ROIs to ROI Manager or just drew a selection
    numROIs = roiManager("count");
    
    if (numROIs == 0) {
        // Check if there's a selection
        if (selectionType() == -1) {
            print("No ROI selected for this image. Skipping.");
            close();
            continue;
        }
        // Add current selection to ROI Manager
        roiManager("Add");
        numROIs = 1;
        print("Using single ROI");
    } else {
        print("Using " + numROIs + " ROI(s)");
    }
    
    // Now process with batch mode for speed
    setBatchMode(true);
    
    // Process each ROI for this image
    for (r = 0; r < numROIs; r++) {
        selectImage(originalID);
        
        // Select current ROI
        roiManager("select", r);
        
        // Get ROI name if available
        roiName = call("ij.plugin.frame.RoiManager.getName", r);
        
        // Duplicate the image with current ROI selected
        run("Duplicate...", "duplicate");
        duplicateID = getImageID();
        
        // Restore the ROI on the duplicated image
        selectImage(duplicateID);
        roiManager("select", r);
        
        // Crop the duplicated image (preserves all XYCZT dimensions)
        run("Crop");
        
        // Create output filename
        baseName = replace(title, ".tif", "");
        baseName = replace(baseName, ".tiff", "");
        
        if (numROIs > 1) {
            // Multiple ROIs: add ROI identifier to filename
            if (roiName != "") {
                newTitle = baseName + "_ROI_" + roiName + ".tif";
            } else {
                newTitle = baseName + "_ROI_" + (r+1) + ".tif";
            }
        } else {
            // Single ROI: just add _crop suffix
            newTitle = baseName + "_crop.tif";
        }
        
        // Save cropped image
        saveAs("Tiff", inputDir + File.separator + newTitle);
        print("Saved: " + newTitle);
        close();
    }
    
    // Close original image
    selectImage(originalID);
    close();
}

// Clean up
roiManager("reset");
setBatchMode(false);
print("\nBatch cropping complete for " + tiffFiles.length + " file(s).");
