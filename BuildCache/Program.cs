using System;
using System.Collections.Generic;
using System.Xml;
using System.Xml.XPath;
using System.IO;
using System.Globalization;

namespace BuildCache {
	public class BuildCache {
		public static void Main(string[] args) {
			string devicesDirectoryPath = "/Users/jason/Projects/AVRFuses-Cocoa/devices";
			string outputPath = "/Users/jason/Projects/AVRFuses-Cocoa/AVRFuses.parts";

			if (args.Length == 2) {
				devicesDirectoryPath = args[0];
				outputPath = args[1];
			}

			Console.WriteLine("Reading from: " + devicesDirectoryPath);
			Console.WriteLine("Writing to: " + outputPath);

			TextWriter writer = new StreamWriter(outputPath);

			String[] files = Directory.GetFiles(devicesDirectoryPath, "*.xml");
			foreach (string file in files) {
				ProcessPartFile(file, writer);
			}
			//ProcessPartFile("/Users/jason/Projects/AVRFuses-Cocoa/devices/ATmega328P.xml", writer);

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
								byte shiftLeftBy = (byte) (bfMask_i & (~(bfMask_i - 1)));
								if (shiftLeftBy > 1) {
									bfValue_i = (byte) (bfValue_i << (shiftLeftBy - 1));
								}
								writer.WriteLine(partName + "," + fuseName + "," + bfMask + ",0x" + bfValue_i.ToString("x2") + "," + bfValueCaption);
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
