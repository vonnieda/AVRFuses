# New Release Process

These instructions describe how to perform a release of AVRFuses. These are intended as a guide for anyone forking
the project, and for the project owner on how to release a new version. This process requires keys that only
the project owner has access to.

1. In XCode, open Info.plist and change Bundle version to the new version number.
2. Use the Product -> Archive option to build and create an archive of the binary.
3. In the Archives tool window which opens after Archive, select the new archive and hit Export.
4. Choose Export as a macOS App and export the archive.
5. Compress the resulting binary into a Zip: Right click in Finder, Compress.
6. Rename the Zip in the format of AVRFuses_1.4.11.zip, replacing the numbers with the new version number.
7. Copy the Zip to the releases folder of the project.
8. Run ./sign_update.rb releases/AVRFuses_1.4.11.zip dsa_priv.pem to create the signature for the archive. Note that this
    requires the private key for the project. Copy the resulting signature. It should look something like
    MC0CFQDUMxu/Mfx1Etj84MwWXXhcbTR0xAIUGqVS9EEFjNeg6bZTMOlmmfXooSQ=.
9. Upload the new archive to the update site and copy the resulting URL.
	Note to self: Do this by editing the AVRFuses page and "Add Media"
10. Edit appcast.xml and add a new <item> record to the top. Update the title, version number, date, signature, length, url 
	and description.
11. Upload the new appcast.xml to the update site.
	Note to self: I do this via SFTP to my hosting company.
12. Commit changes to Github.
