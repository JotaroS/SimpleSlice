//SuperSkein!
//
//SuperSkein is an open source mesh slicer.
//Note!  Only takes binary-coded STL.  ASCII
//STL just breaks it for now.

//Slicing Parameters-- someone should make
//a GUI menu at some point...
//Sorted here according to units

//"funny" dimensionality
float PrintHeadSpeed = 2000.0;

//Measured in millimeters
float LayerThickness = 0.3;
float Sink = 2;


//Dimensionless
float PreScale = 0.6;
//String FileName = "dense800ktris.stl";
String FileName = "sculpt_dragon.stl";
//String FileName = "linetesting.stl";


//Display Properties
float BuildPlatformWidth = 100;
float BuildPlatformHeight = 100;
float GridSpacing = 10;
float DisplayScale = 5;

//End of "easy" modifications you can make...
//Naturally I encourage everyone to learn and
//alter the code that follows!
int t=0;
float tfloat=0;
float[] Tri = new float[9];
ArrayList Slice;
Mesh STLFile;
PrintWriter output;
float MeshHeight;


void setup(){
  size(int(BuildPlatformWidth*DisplayScale),int(BuildPlatformHeight*DisplayScale));

  Slice = new ArrayList();
  print("Loading STL...\n");
  //Load the .stl
  //Later we should totally make this runtime...
  STLFile = new Mesh(FileName);


  //Scale and locate the mesh
  STLFile.Scale(PreScale);
  //Put the mesh in the middle of the platform:
  STLFile.Translate(-STLFile.bx1,-STLFile.by1,-STLFile.bz1);
  STLFile.Translate(-STLFile.bx2/2,-STLFile.by2/2,0);
  STLFile.Translate(0,0,-LayerThickness);  
  STLFile.Translate(0,0,-Sink);


  print("File Loaded, Slicing:\n");
  print("X: " + CleanFloat(STLFile.bx1) + " - " + CleanFloat(STLFile.bx2) + "   ");
  print("Y: " + CleanFloat(STLFile.by1) + " - " + CleanFloat(STLFile.by2) + "   ");
  print("Z: " + CleanFloat(STLFile.bz1) + " - " + CleanFloat(STLFile.bz2) + "   \n");
  //Spit GCODE!
  Line2D Intersection;
  Line2D lin;
  output = createWriter("output.gcode");

  //Header:
  output.println("G21");
  output.println("G90");
  output.println("M103");
  output.println("M105");
  output.println("M104 s220.0");
  output.println("M109 s110.0");
  output.println("M101");

  Slice ThisSlice;
  float Layers = STLFile.bz2/LayerThickness;
  for(float ZLevel = 0;ZLevel<(STLFile.bz2-LayerThickness);ZLevel=ZLevel+LayerThickness)
  {
    ThisSlice = new Slice(STLFile,ZLevel);
    print("Slicing: ");
    TextStatusBar(ZLevel/STLFile.bz2,50);
    print("\n");
    lin = (Line2D) ThisSlice.Lines.get(0);
    output.println("G1 X" + lin.x1 + " Y" + lin.y1 + " Z" + ZLevel + " F" + PrintHeadSpeed);
      for(int j = 0;j<ThisSlice.Lines.size();j++)
      {
        lin = (Line2D) ThisSlice.Lines.get(j);
        output.println("G1 X" + lin.x2 + " Y" + lin.y2 + " Z" + ZLevel + " F" + PrintHeadSpeed);
      }
  }
  output.flush();
  output.close();


  print("Finished Slicing!  Bounding Box is:\n");
  print("X: " + CleanFloat(STLFile.bx1) + " - " + CleanFloat(STLFile.bx2) + "   ");
  print("Y: " + CleanFloat(STLFile.by1) + " - " + CleanFloat(STLFile.by2) + "   ");
  print("Z: " + CleanFloat(STLFile.bz1) + " - " + CleanFloat(STLFile.bz2) + "   ");
  if(STLFile.bz1<0)print("\n(Values below z=0 not exported.)");


  //Match viewport scale to 1cm per gridline
  STLFile.Scale(DisplayScale);
  STLFile.Translate(BuildPlatformWidth*DisplayScale/2,BuildPlatformHeight*DisplayScale/2,-STLFile.bz1);
  MeshHeight=STLFile.bz2-STLFile.bz1;

}

void draw()
{
  background(0);
  stroke(0);
  strokeWeight(2);

  //Generate a Slice
  Line2D Intersection;
  Slice = new ArrayList();
  for(int i = STLFile.Triangles.size()-1;i>=0;i--)
  {
    
    Triangle tri = (Triangle) STLFile.Triangles.get(i);
    Intersection = tri.GetZIntersect(MeshHeight*mouseX/width);
    if(Intersection!=null)Slice.add(Intersection);
  }


  //Draw the grid
  stroke(80);
  strokeWeight(1);
  for(float px = 0; px<(BuildPlatformWidth*DisplayScale+1);px=px+GridSpacing*DisplayScale)line(px,0,px,BuildPlatformHeight*DisplayScale);
  for(float py = 0; py<(BuildPlatformHeight*DisplayScale+1);py=py+GridSpacing*DisplayScale)line(0,py,BuildPlatformWidth*DisplayScale,py);
  

  //Draw the profile
  stroke(255);
  strokeWeight(2);
  for(int i = Slice.size()-1;i>=0;i--)
  {
    Line2D lin = (Line2D) Slice.get(i);
    //lin.Scale(15);
    line(lin.x1,lin.y1,lin.x2,lin.y2);
  }
}


//Convert the binary format of STL to floats.
float bin_to_float(byte b0, byte b1, byte b2, byte b3)
{
  int exponent, sign;
  float significand;
  float finalvalue=0;
  
  exponent = (b3 & 0x7F)*2 | (b2 & 0x80)>>7;
  sign = (b3&0x80)>>7;
  exponent = exponent-127;
  significand = 1 + (b2&0x7F)*pow(2,-7) + b1*pow(2,-15) + b0*pow(2,-23);  //throwing away precision for now...

  if(sign!=0)significand=-significand;
  finalvalue = significand*pow(2,exponent);

  return finalvalue;
}


//Display floats cleanly!
float CleanFloat(float Value)
{
  Value = Value * 1000;
  Value = round(Value);
  return Value / 1000;
}



//Print a status bar
void TextStatusBar(float Percent, int Width)
{
  print("[");
  int Stars = int(Percent*Width)+1;
  int Dashes = Width-Stars;
  for(int i = 0; i<Stars; i++)print("X");
  for(int i = 0; i<Dashes; i++)print(".");
  print("]");
}

