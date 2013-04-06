using System;
using System.Collections.Generic;
using System.Xml;
using System.IO;
using System.Globalization;

namespace BuildCache
{
	public class BuildCache
	{
		Dictionary<string, PartDefinition> parts = new Dictionary<string, PartDefinition>();
		
		static void Main(string[] args)
		{
			new BuildCache(args);
		}

		public BuildCache(string[] args)
		{
			string path = args[0];

			String[] files = Directory.GetFiles(path, "*.xml");
			foreach (string file in files) {
				PartDefinition part = LoadPartDefinition(file);
				parts.Add(part.name, part);
			}

			path = args[1];

			TextWriter writer = new StreamWriter(path);
            foreach (PartDefinition part in parts.Values) {
                foreach (FuseDefinition fuse in part.fuses.Values) {
                    foreach (FuseSetting fuseSetting in fuse.settings) {
                        writer.WriteLine(part.name + "," +
                            fuseSetting.fuse + ",0x" +
                            fuseSetting.mask.ToString("x2") + ",0x" +
                            fuseSetting.value.ToString("x2") + "," +
                            fuseSetting.text);
                    }
                }
            }
            writer.Close();
		}

		private PartDefinition LoadPartDefinition(string path)
		{
			XmlTextReader reader = new XmlTextReader(new FileStream(path, FileMode.Open, FileAccess.Read));

			string partName = Path.GetFileNameWithoutExtension(path);
			PartDefinition part = new PartDefinition(partName);

			while (reader.Read()) {
				if (reader.NodeType == XmlNodeType.Element && reader.Name == "FUSE") {
					ParseFuse(reader, part);
				}
			}

			reader.Close();

			return part;
		}

		private void ParseFuse(XmlTextReader reader, PartDefinition part)
		{
			List<string> fuseNames = new List<string>();

			while (reader.Read()) {
				if (reader.NodeType == XmlNodeType.Element) {
					if (reader.Name == "LIST") {
						reader.Read();
						String[] parts = reader.Value.Substring(1, reader.Value.Length - 2).Split(':');
						foreach (string fuseName in parts) {
							fuseNames.Add(fuseName);
						}
					}
					else if (fuseNames.Contains(reader.Name)) {
						ParseFuseLowOrHighOrExtended(reader, part);
					}
				}
				else if (reader.NodeType == XmlNodeType.EndElement && reader.Name == "FUSE") {
					break;
				}
			}
		}

		private void ParseFuseLowOrHighOrExtended(XmlTextReader reader, PartDefinition part)
		{
			string name = reader.Name;

			FuseDefinition fuse = new FuseDefinition(name);

			while (reader.Read()) {
				if (reader.NodeType == XmlNodeType.Element) {
					if (reader.Name != "TEXT" && reader.Name.StartsWith("TEXT")) {
						ParseFuseLowOrHighOrExtendedText(reader, fuse);
					}
				}
				else if (reader.NodeType == XmlNodeType.EndElement && reader.Name == name) {
					part.fuses.Add(fuse.name, fuse);
					break;
				}
			}
		}

		private void ParseFuseLowOrHighOrExtendedText(XmlTextReader reader, FuseDefinition fuse)
		{
			string name = reader.Name;

			FuseSetting fuseSetting = new FuseSetting();
			fuseSetting.fuse = fuse.name;

			while (reader.Read()) {
				if (reader.NodeType == XmlNodeType.Element) {
					if (reader.Name == "MASK") {
						reader.Read();
						fuseSetting.mask = Byte.Parse(reader.Value.Substring(2), NumberStyles.HexNumber);
					}
					else if (reader.Name == "VALUE") {
						reader.Read();
						fuseSetting.value = Byte.Parse(reader.Value.Substring(2), NumberStyles.HexNumber);
					}
					else if (reader.Name == "TEXT") {
						reader.Read();
						fuseSetting.text = reader.Value;
					}
				}
				else if (reader.NodeType == XmlNodeType.EndElement && reader.Name == name) {
					fuse.settings.Add(fuseSetting);
					break;
				}
			}
		}
	}
	
	public class PartDefinition
	{
		public string name;
		public Dictionary<string, FuseDefinition> fuses = new Dictionary<string, FuseDefinition>();

		public PartDefinition(string name)
		{
			this.name = name;
		}
	}

	public class FuseDefinition
	{
		public string name;
		public List<FuseSetting> settings = new List<FuseSetting>();

		public FuseDefinition(string name)
		{
			this.name = name;
		}
	}

	public class FuseSetting
	{
		public string fuse;
		public byte mask;
		public byte value;
		public string text;

		public FuseSetting()
		{
		}

		public override string ToString()
		{
			return text;
		}
	}
}
