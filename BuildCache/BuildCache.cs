using System;
using System.Collections.Generic;
using System.Xml;
using System.Xml.XPath;
using System.IO;
using System.Globalization;

namespace BuildCache {
	public class BuildCache {
		public static void Main(string[] args) {
			if (args.Length < 2) {
			    Console.WriteLine("BuildCache.exe <path to AVR Studio devices directory> <path to AVRFuses.parts output file>");
			    return;
			}

			string devicesDirectoryPath = args[0];
			string outputPath = args[1];

			Console.WriteLine("Reading from: " + devicesDirectoryPath);
			Console.WriteLine("Writing to: " + outputPath);

			TextWriter writer = new StreamWriter(outputPath);

			String[] files = Directory.GetFiles(devicesDirectoryPath, "*.xml");
			foreach (string file in files) {
				ProcessPartFile(file, writer);
			}

			writer.Close();
		}

		private static void ProcessPartFile(string file, TextWriter writer) {
			string partName = Path.GetFileNameWithoutExtension(file);
			Console.WriteLine("Processing: " + partName);
			XPathDocument doc = new XPathDocument(file);
			
			XPathNavigator nav = doc.CreateNavigator();
			
			XPathNodeIterator i = nav.Select("/avr-tools-device-file/modules/module[@name='FUSE']");
			while (i.MoveNext()) {
				XPathNavigator module = i.Current;
				XPathNavigator fuseRegisterGroup = module.SelectSingleNode("register-group[@name='FUSE']");
				if (fuseRegisterGroup == null) {
					continue;
				}
				XPathNodeIterator fuseRegisters = fuseRegisterGroup.Select("register[@name='HIGH' or @name='LOW' or @name='EXTENDED']");
				while (fuseRegisters.MoveNext()) {
					XPathNavigator fuseRegister = fuseRegisters.Current;
					string fuseName = fuseRegister.GetAttribute("name", "");
					XPathNodeIterator bitfields = fuseRegister.Select("bitfield");
					while (bitfields.MoveNext()) {
						XPathNavigator bitfield = bitfields.Current;
						string bfCaption = bitfield.GetAttribute("caption", "");
						string bfMask = bitfield.GetAttribute("mask", "");
						string bfValuesName = bitfield.GetAttribute("values", "");
						if (bfValuesName != String.Empty) {
							XPathNodeIterator bfValues = module.Select(string.Format("value-group[@name='{0}']/value", bfValuesName));
							while (bfValues.MoveNext()) {
								XPathNavigator bfValue = bfValues.Current;
								string bfValueCaption = bfValue.GetAttribute("caption", "");
								string bfValueValue = bfValue.GetAttribute("value", "");
								byte bfMask_i = Convert.ToByte(bfMask, 16);
								byte bfValue_i = Convert.ToByte(bfValueValue, 16);
								byte bfMask_i_tmp = bfMask_i;
								// Shift the value to the left by the number of 0 LSBs in the mask
								// This effectively lines the value up with the mask
								while ((bfMask_i_tmp & 1) == 0) {
								    bfMask_i_tmp >>= 1;
								    bfValue_i <<= 1;
								}
								
								writer.WriteLine(partName + "," + fuseName + "," + bfMask + ",0x" + bfValue_i.ToString("x2") + "," + bfCaption + ": " + bfValueCaption);
							}
						}
						else {
							writer.WriteLine(partName + "," + fuseName + "," + bfMask + ",0x00," + bfCaption);
						}
					}
				}
			}
		}
	}
}
