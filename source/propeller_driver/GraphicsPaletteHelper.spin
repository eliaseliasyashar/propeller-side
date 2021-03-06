{{
┌──────────────────────────────────────────┐
│ Graphics Palette Helper                  │
│ Author: Jim Fouch                        │               
│ Copyright (c) 2010 Jim Fouch             │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

This example show how you create a graphics display with the propeller.

It Uses a modified version of the standard Graphics.spin file

It uses Output pins 12..15 for the TV output. It's configured to work with NTSC, but could be modified to work with PAL.

A Button shound be wired to Pin 7 and pulled high. This button will allow you to see an overlayed grid showing the cells.



}}

CON  {<object declarations, code, and comments>}
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000
'  _stack = ($3000 + $3000 + 100) >> 2   'accomodate display memory and stack
  _stack = (200) >> 2   'accomodate display memory and stack
  ' One Screen Takes $3000 Bytes
  ' Two are used for double buffering
  
  ' BMW 8.8" CCC iDrive monitor: 640x240 (full screen), 400x240 (split screen)
  ' Full = 40 * 15 tiles, Split = 25 * 15 tiles
  ' Memory usage of 32KB max: mem = 4*longs = (x_res/32) * y_res
  '    Ex: (512/32)*384 = 6144 longs (24KB), leaving 2048 longs (8KB) for pgm space 
  x_tiles = 16 ' 256 Pixels
  y_tiles = 14 ' 224 Pixels
  'y_tiles = 12 ' 192 Pixels
  'x_tiles = 18

  ' advanced GFX commands for GFX tile engine
  GPU_GFX_BASE_ID         = 192                  ' starting id for GFX commands to keep them away from normal command set
  GPU_GFX_NUM_COMMANDS    = 26                   ' number of GFX commands

  GPU_GFX_ONE_GAUGE       = (0+GPU_GFX_BASE_ID)
  GPU_GFX_TWO_GAUGE       = (1+GPU_GFX_BASE_ID)
  GPU_GFX_FOUR_GAUGE      = (2+GPU_GFX_BASE_ID)
  GPU_GFX_SIX_GAUGE_1     = (3+GPU_GFX_BASE_ID)
  GPU_GFX_SIX_GAUGE_2     = (4+GPU_GFX_BASE_ID)
  GPU_GFX_PARAM_LIST      = (5+GPU_GFX_BASE_ID)
  GPU_GFX_TIMERXY         = (6+GPU_GFX_BASE_ID)
  GPU_GFX_TIMER_SETXY     = (7+GPU_GFX_BASE_ID)
  GPU_GFX_CONFIG_SET      = (8+GPU_GFX_BASE_ID)
  GPU_GFX_PROCEDE_PGM     = (9+GPU_GFX_BASE_ID)
  GPU_GFX_FIRMWARE_PGM    = (10+GPU_GFX_BASE_ID)
  GPU_GFX_DATA_LOG        = (11+GPU_GFX_BASE_ID)
  GPU_GFX_CAN_SNIFFER     = (12+GPU_GFX_BASE_ID)
  GPU_GFX_V1              = (13+GPU_GFX_BASE_ID)
  GPU_GFX_REFRESH_ACTIVE  = (14+GPU_GFX_BASE_ID)
  GPU_GFX_TERMINAL_PRINT  = (15+GPU_GFX_BASE_ID)
  GPU_GFX_BOTTOM_MENU     = (16+GPU_GFX_BASE_ID)
  GPU_GFX_HIGHLIGHT       = (17+GPU_GFX_BASE_ID)
  GPU_GFX_CLS_MAIN        = (18+GPU_GFX_BASE_ID)
  GPU_GFX_SPLASH_IN       = (19+GPU_GFX_BASE_ID)
  GPU_GFX_SPLASH_OUT      = (20+GPU_GFX_BASE_ID)
  GPU_GFX_DRAW_BOX        = (21+GPU_GFX_BASE_ID)
  GPU_GFX_PRINT_XY        = (22+GPU_GFX_BASE_ID)
  GPU_GFX_PRINT_SETXY     = (23+GPU_GFX_BASE_ID)
  GPU_GFX_TIMERFATS       = (24+GPU_GFX_BASE_ID)
  GPU_GFX_TIMER_SETFATS   = (25+GPU_GFX_BASE_ID)
  
  paramcount = 14       
 
  'thickness = 2

  'TachSpacing = $137

  ' Parameter List Display
  Param_ColA_Descrip = 50
  Param_ColA_Var     = 120
  Param_ColB_Descrip = 180
  Param_ColB_Var     = 210
  Param_Col_Spacing  = 10

  ' Colors
  '(reference http://propeller.wikispaces.com/Colors)
  ' http://www.rayslogic.com/propeller/programming/TV_Colors.htm
  CL_Black      = $02
  CL_Grey1      = $03
  CL_Grey2      = $04
  CL_Grey3      = $05
  CL_Grey4      = $06
  CL_White      = $07
  CL_Blue       = $0A
  CL_DarkBlue   = $3A
  CL_DarkGreen  = $4A
  CL_Red        = $48
  CL_Brown      = $28
  CL_Yellow     = $9E
  CL_Purple     = $88
  CL_DarkPurple = $EA
  CL_Green      = $F8
  CL_Orange     = $28
  CL_LtOrange   = $AE

{  ' Buttons
  ShowGrid = 7

  ' Signal Masks
  LeftTurnMask  = %0000_0001
  RightTurnMask = %0000_0010
  HighBeamMask  = %0000_0100
  LowFuelMask   = %0000_1000
  LowOilMask    = %0001_0000
  FIMask        = %0010_0000
  DistanceMask  = %0100_0000 ' 0=Miles , 1 = Kilometers
  HESCMask      = %1000_0000

  Gallon        = 49907
  FullTank      = 225081   ' 4.51 Gallon Allows for 1/4 Gallon Reserve (Not Counted)
}

  'Gauge Types
  RpmG         = 0      'int
  BoostG       = 1      'dec
  ActIgnAdvG   = 2      'dec
  IgnCorrG     = 3      'dec
  DbwThrottleG = 4      'int
  SpeedG       = 5      'dec
  MapSelectG   = 6      'int
  IatG         = 7      'int
  MethFlowG    = 8      'int
  OilTempG     = 9      'int
  DmeIgnAdvG   = 10     'dec
  AtBoostLvlG  = 11     'dec
  DmeCodesG    = 12     'int
  AfrBank1G    = 13     'dec
  AfrBank2G    = 14     'dec
  BoostExtG    = 15     'dec
  TimerG       = 16     'dec
  MaxTypeG     = 16
  MaxProcedeParams = 15

  SCREEN_OFFSET   = 10

  ONE_GAUGE       = 10
  TWO_GAUGE       = 11
  FOUR_GAUGE      = 12
  SIX_GAUGE       = 13
  PARAM_LIST      = 14
  TIMER_XY        = 15
  TIMER_FATS      = 16
  CONFIG_SET      = 17
  PROCEDE_FW_PGM  = 18
  PROCEDE_MAP_PGM = 19
  CAN_SNIFFER     = 20
  IDRIVINO_RESET  = 21
  DATA_LOG        = 22
  VALENTINE1      = 23
  MENU_BAR        = 30
  MAX_SCREEN_TYPE = 14

  BottomMenuHeight = 32
  MaxGaugesShown = 4

VAR

  long  bitmap_base  
  long  display_base 

  word  screen[x_tiles * y_tiles]
  
  long  tv_status     '0/1/2 = off/visible/invisible           read-only
  long  tv_enable     '0/? = off/on                            write-only
  long  tv_pins       '%ppmmm = pins                           write-only
  long  tv_mode       '%ccinp = chroma,interlace,ntsc/pal,swap write-only
  long  tv_screen     'pointer to screen (words)               write-only
  long  tv_colors     'pointer to colors (longs)               write-only               
  long  tv_hc         'horizontal cells                        write-only
  long  tv_vc         'vertical cells                          write-only
  long  tv_hx         'horizontal cell expansion               write-only
  long  tv_vx         'vertical cell expansion                 write-only
  long  tv_ho         'horizontal offset                       write-only
  long  tv_vo         'vertical offset                         write-only
  long  tv_broadcast  'broadcast frequency (Hz)                write-only
  long  tv_auralcog   'aural fm cog                            write-only
  long  colors[16]

  'Byte DisplayRam[12288+64] ' Display Ram. Allow enough extra to Align to a 64 Byte Boundry
  byte DisplayRam[14336+64] ' Display Ram. Allow enough extra to Align to a 64 Byte Boundry
  'Byte DisplayRam[16128+64] ' Display Ram. Allow enough extra to Align to a 64 Byte Boundry
    
  'Text variables
  byte Temp[12], HexTemp[12]
  long term_x, term_xoffset, term_y, term_yoffset,column_marker

  long ActiveArray[MaxGaugesShown], _ActiveArray[MaxGaugesShown]
  long PeakArray[MaxGaugesShown] ',PeakArrayB[MaxGaugesShown]
  long GaugeArray[MaxGaugesShown]
  long ParamArray[MaxTypeG],_ParamArray[MaxTypeG]
  
  long LastTab, LastMain
  long CenterX,CenterY

  byte warnon[MaxGaugesShown]
  byte print_x, print_y

  long hex_answer

OBJ
  tv      : "tv"
  gr      : "graphics"

PUB Start|x

  'start tv
  longmove(@tv_status, @tvparams, paramcount)
  tv_screen := @screen
  tv_colors := @colors
  tv.start(@tv_status)

  ' Establish Display Memory, Make sure it's on a 64 Byte Boundry
  display_base := bitmap_base := (@DisplayRam + $3F) & $7FC0
   
  'Define 4 color palette, available for use per tile area
  SetColorPallet(0,CL_Black,CL_White,CL_Red,CL_Grey3)  'For Main window
  SetColorPallet(1,CL_Black,CL_Grey3,CL_Orange,CL_Red)    'for gauges
  SetColorPallet(2,CL_Black,CL_White,CL_Grey3,CL_Orange) 'Bottom menu colors
  'SetColorPallet(3,CL_Black,CL_White,CL_Grey4,CL_Green)  'for text          
  'SetColorPallet(4,$4E,CL_White,$48,$AA)       ' Idiot Lights   
  'SetColorPallet(5,$8B,CL_White,$8E,$AA)
  'SetColorPallet(6,$6E,$F8,CL_Red,CL_Blue)
  'SetColorPallet(7,CL_Black,$6D,CL_Red,CL_Blue)
  'SetColorPallet(8,CL_Black,CL_White,CL_Red,$F8) ' Gear Indicator            

  'Init entire screen to color palette 0 (last param = 0)
  SetAreaColor(0,0,TV_HC-1,TV_VC-1,0) ' Defaults all Screen to Color Palette #0
      
  'start and setup graphics
  gr.start
  gr.setup(x_tiles, y_tiles, 0 , 0, bitmap_base) '3rd param = x_origin, 4th param = y_origin
                                                 'change these to change the x.y reference pts
'  waitcnt ( CNT + 20000000 * 5 )
  
  'Terminal printer inits
  term_x := 16
  term_y := (y_tiles*16)-16
  term_xoffset := 0
  term_yoffset := 0
  column_marker := 0

  'Param list DAT string inits
  x := 0
  repeat while ParamListArray[x] <> 0
    ParamListArray[x] := @@ParamListArray[x]
    x++
  x := 0
  repeat while ParamLabelArray[x] <> 0
    ParamLabelArray[x] := @@ParamLabelArray[x]
    x++  

  'Init screen
  gr.clear
  NormalText
  gr.color(1)

  'Set up generic array, this will represent different parameters depending
  '  on the active screen and/or gauge
  repeat x from 0 to (MaxGaugesShown-1)
    ActiveArray[x] := 0
    _ActiveArray[x] := -1
    PeakArray[x] := -999
    GaugeArray[x] := -1
    warnon[x] := 0

  InitParamArray

  CenterX := 86
  CenterY := 88
  LastTab := 0
  LastMain := 0

  print_x := 0
  print_y := 0
  
  'ShowTiles
  'waitcnt ( CNT + 50000000 * 5 )

    

Pri FixedDec(Value)|i,k,V,Vtemp

  V:=Value/100 'Check for Whole Number

  'init text
  Repeat k From 0 to 11
    Temp[k] := 0
  k := 0

  ' Check for negative sign  
  if Value < 0
    -V
    -Value
    Temp[K++]:="-"

  'Calc whole numbers
  i := 1_000_000_000
  repeat 10
    if V => i
      Temp[k++]:= Lookup(V / i: 49,50,51,52,53,54,55,56,57)
      V //= i
      Result~~
    elseif Result or i == 1
      Temp[k++]:="0"
    i /= 10
    
  Temp[k++]:="."

  ' Now Calc Fractions to 1 decimal place
  V:= Value/100
  V:= V*100
  V:= Value - V   
  Case V
    0..9:   Temp[K++]:="0"
    10..19: Temp[K++]:="1"
    20..29: Temp[K++]:="2"
    30..39: Temp[K++]:="3"
    40..49: Temp[K++]:="4"
    50..59: Temp[K++]:="5"
    60..69: Temp[K++]:="6"
    70..79: Temp[K++]:="7"
    80..89: Temp[K++]:="8"
    90..99: Temp[K++]:="9"


Pub DisplayDec(V)|i,k

  k := 0
  i := 0
  
  Repeat k From 0 to 11
    Temp[k] := 0
  
  k:=0

  ' Check for negative  
  if V < 0
    -V
    Temp[K++]:="-"

  ' Print a decimal number
  i := 1_000_000_000
  repeat 10
    if V => i
      Temp[k++]:= Lookup(V / i: 49,50,51,52,53,54,55,56,57)
      V //= i
      Result~~
    elseif Result or i == 1
      Temp[k++]:="0"
    i /= 10


Pub ClearScreen

  'Clear the entire bitmap tilespace
  gr.clear

  'Reset the x,y tile pointers for terminal printing
  term_x := 16
  term_y := (y_tiles*16)-16

Pub ClearMainWindow

  ClearTiles(0,2,x_tiles,y_tiles-2)

  'Reset the x,y tile pointers for terminal printing
  term_x := 16
  term_y := (y_tiles*16)-16

Pri NormalText
  Gr.TextMode(1,1,6,%0101)
  Gr.ColorWidth(1,0)

Pri ClearTiles(X,Y,W,H)
  gr.Color(0)
  Gr.FilledBox(X*16,Y*16,W*16,H*16)
  
Pub ShowTiles| x, y
  ' This Sub Will Draw a Grid Outlining each Tile
  gr.color(1)
  Repeat X From 0 to X_tiles-1
    gr.Plot(X * 16,0)
    gr.line(X * 16,y_Tiles * 16)  
  Repeat Y From 0 to y_Tiles-1
    gr.Plot(0,Y*16)
    gr.line(X_Tiles * 16,Y * 16)

{
Pri PlaceChar(x,y,Char)|i,j,k,S,w
  S := Display_Base+(64*Y)+(768*x) 
  k := S - 64 * 2
  Repeat i from 0 to 64
    'Word[S][i] := Word[$9000][i] Or %11111111_11111111
    ' WordMove(S+I*2,$9000+i*2,1)
    Word[S][i] := (Word[$9000+I*2] & %10101010_10101010)
    'Word[S][i] := (Word[$9000+I*2] & %01010101_01010101)



Pub DisplayTime(X,Y,H,M)

  ' Display time
  gr.color(3)
  gr.FilledBox(X-6,Y+2,4*16,20)
  gr.color(1)    
   
  If H==0
    H:=12 ' 12 AM
  IF H>12 ' ?? PM
    H:=H-12
  Gr.Width(0)
  Gr.TextMode(2,2,6,%0101)
  If H<10 
    DisplayDec(X+12,Y+11,H)
  Else
    DisplayDec(X+6,Y+11,H)  
  gr.Text(X+20,Y+10,String(":"))
  If M<10
    Gr.text(X+28,Y+11,string("0"))
    DisplayDec(X+39,y+11,M)
  Else
    DisplayDec(X+34,y+11,M)

}

Pub SetAreaColor(X1,Y1,X2,Y2,ColorIndex)|DX,DY
  Repeat DX from X1 to X2
    Repeat DY from Y1 to Y2
      SetTileColor(DX,DY,ColorIndex)    

Pub SetTileColor(x, y, ColorIndex)
   screen[y * tv_hc + x] := display_base >> 6 + y + x * tv_vc + ((ColorIndex & $3F) << 10)

Pub SetColorPallet(ColorIndex,Color1,Color2,Color3,Color4)
  colors[ColorIndex] := (Color1) + (Color2 << 8) +  (Color3 << 16) + (Color4 << 24)

'iDrivino Custom Functions

'Draw Parameter List Display
Pub ParamList(param_val,param_num)|I

  NormalText
  gr.color(1)

  if (param_num <> $9D) 
    ParamArray[param_num] := param_val

  Case param_num
    $9D: 'special case to draw param list from scratch
      repeat I from 0 to (MaxProcedeParams-1)
        gr.text(Param_ColA_Descrip,(y_tiles*16)-(I*Param_Col_Spacing)-15,ParamListArray[I])
        gr.text(Param_ColB_Descrip,(y_tiles*16)-(I*Param_Col_Spacing)-15,ParamLabelArray[I])
        _ParamArray[I] := -10        
    0..(MaxProcedeParams-1): 
      if (ParamArray[param_num] <> _ParamArray[param_num])
        'overwrite old numbers in black
        gr.color(0)
        if ((param_num == BoostG) or (param_num == ActIgnAdvG) or (param_num == IgnCorrG) or (param_num == DmeIgnAdvG) or (param_num == AtBoostLvlG) or (param_num == AfrBank1G) or (param_num == AfrBank2G) or (param_num == SpeedG))
          FixedDec(_ParamArray[param_num])
        else
          DisplayDec(_ParamArray[param_num])
        gr.text(Param_ColA_Var,(y_tiles*16)-(param_num*Param_Col_Spacing)-15,@Temp)

        'write new numbers in white        
        gr.color(1)
        if ((param_num == BoostG) or (param_num == ActIgnAdvG) or (param_num == IgnCorrG) or (param_num == DmeIgnAdvG) or (param_num == AtBoostLvlG) or (param_num == AfrBank1G) or (param_num == AfrBank2G) or (param_num == SpeedG))
          FixedDec(ParamArray[param_num])
        else
          DisplayDec(ParamArray[param_num])          
        gr.text(Param_ColA_Var,(y_tiles*16)-(param_num*Param_Col_Spacing)-15,@Temp)

        'Save new param to prev 
        _ParamArray[param_num] := ParamArray[param_num]

    
'Tach style gauge
{
Pri TachStyle(gauge_x,gauge_y,scaling,low_limit,high_limit,low_limit_warn,high_limit_warn,step_size)|I,J,TachAngle,low_end,high_end,low_warn_limit1,low_warn_limit2,high_warn_limit1,high_warn_limit2

  {
  angle: E=0 (0), N=90 ($800), W=180 ($1000), S=270 ($1800), E=360/0 again ($1fff rolls over)
  $1fff/360 = 22.75277, so 22.75277 * angle in degs = $xxxx (hex angle)
  }
           
  TachAngle := $1000
  TachSpacing :=  $1000/((high_limit - low_limit)/step_size)
  Gr.TextMode(1,1,6,%0101)

  low_end := low_limit/step_size
  high_end := high_limit/step_size

  low_warn_limit1 := low_end
  low_warn_limit2 := low_limit_warn/step_size

  high_warn_limit1 := high_limit_warn/step_size
  high_warn_limit2 := high_end
  
  Repeat I from low_end to high_end 
    Case I
      {low_warn_limit1..low_warn_limit2:
        if (low_warn_limit1 <> low_warn_limit2)
          gr.Color(2) ' Red
        else
          gr.Color(1) ' White
      } 
      high_warn_limit1..high_warn_limit2:
        if (high_warn_limit1 <> high_warn_limit2)
          gr.Color(2) ' Red
        else
          gr.Color(1) ' White
      Other : gr.Color(1) ' White 

    gr.textarc(tachCenterX,TachCenterY,80,80,TachAngle,Lookup(I+1: @Tach0,@Tach1,@Tach2,@Tach3,@Tach4,@Tach5,@Tach6,@Tach7,@Tach8,@Tach9))
    gr.color(1)

    Repeat J from 50 to 75 Step 15                     
      gr.Arc(tachCenterX,TachCenterY,J,J,TachAngle,0,1,0)
    TachAngle := TachAngle - TachSpacing
}

PRI ArcDial(xc,yc,cscale,ticks,cstart,cend,direc)|k,div

'' Draws a set of ticks around an arbitrary part of a circle to form a scale for a pointer/clock
''
'' Can also use high densities to create rotational bar graphs 
'' xc,yc          - center of scale
'' cscale         - size of scale, $100 = 1x size
'' ticks          - number of divisions
'' cstart         - start angle in bits[12..0] (0..$1FFF = 0°..359.956°)
'' cend           - end angle, should be CCW of start angle
'' direc          - 0 is clockwise, 1 is counter clockwise
'' Note about angles: $0 = East, $800 = North, $1000 = West, $1800 = South, $1FFF = 1 LSB short of East 
      
  if (direc == 0)
    div := (cstart-cend)<<15/ticks
  else
    div := (cend-cstart)<<15/ticks
  'div := (cstart-cend)<<15/ticks

  repeat k from 0 to ticks
    if (direc == 0)  
      gr.vec(xc,yc,cscale,(cstart-((k*div)>>15)),@tickvec)
    else
      gr.vec(xc,yc,cscale,((k*div)>>15-cstart),@tickvec2)
      'gr.vec(xc,yc,cscale,((k*div)>>15),@tickvec2)      
  
{PRI  hand(xc,yc,pscale,hstart,hend,ticks,position)|k,div

'' Places a hand/pointer on the screen

'' xc,yc          - center of scale
'' cscale         - size of scale, $100 = full size
'' hstart         - start angle in bits[12..0] (0..$1FFF = 0°..359.956°)
'' hend           - end angle, should be CCW of start angle
'' ticks          - number of divisions
'' position       - position on scale from 0 to ticks (0 and ticks are same place on full clock)          

   position := ticks - position      ' Remove if you want position to get larger CCW

   if hend < hstart
      div := ($1FFF-(hstart-hend))<<15/ticks
   elseif hend == hstart
      div := $1FFF<<15/ticks
   else
      div := (hend-hstart)<<15/ticks

   if  (position * div + hstart) > $1FFF       
      gr.vec(xc,yc,pscale,(position*div)>>15 + hstart - $1FFF,@pointer)
   else
      gr.vec(xc,yc,pscale,(position*div)>>15 + hstart,@ pointer)
}

PRI   BarTick(x,y,orient,cscale,ticks,pixelct)|k,div

'' Draws a set of ticks in a horizontal or vertical arrangement
''
'' Can also use high densities to create bar graphs 


'' x,y          - bottom of scale
'' orient         - scale orientation, 0=vert, 1=horiz
'' cscale         - size of scale, $100 = full size
'' ticks          - number of divisions
'' cstart         - start
'' cend           - end 
      
  div := pixelct/ticks

  repeat k from 0 to ticks
    if (orient == 0) 'vert  
      gr.vec(x,(y-(k*div)),cscale,0,@tickvec)
    else 'horiz  
      gr.vec(y-(k*div),y,cscale,$800,@tickvec)
     
'Display a gauge based on input param and top left x/y location
Pri ShowGaugeType(gauge_pos,scaling,isUpdate)|i,k,LabelAngle,scaleL,scaleM,scaleS,showPeak,scaleRPM,scaleBoost,scaleBar,descripY,unitsY,dialXoffset,dialYoffset,scaleTick,scaleArc,peakAX,peakBX,peakY,digOffset,threshold,arcDiv,scaleLwidth,scaleMwidth,scaleSwidth,tempmin,tempmax,adjust

  'Update drawing locations based on # of gauges needed to display
  Case scaling
    1 :
      CenterX := x_tiles*16/2
      CenterY := (y_tiles*16-BottomMenuHeight)/2+25
      scaleL := 3
      scaleLwidth := 3
      scaleM := 2
      scaleMwidth := 1
      scaleS := 1
      scaleSwidth := 0
      showPeak := TRUE
      scaleRPM := 112
      scaleBoost := 116
      descripY := -60
      unitsY := 40
      dialXoffset := -2
      dialYoffset := -25
      scaleTick := $120
      scaleArc := $100
      peakAX := 220
      peakY := 206
      digOffset := 0
      scaleBar := 100
      
    2:
      if (gauge_pos == 0)
        CenterX := x_tiles*16/4
      else
        CenterX := x_tiles*16/4 + (x_tiles*16/2)
      CenterY := (y_tiles*16-BottomMenuHeight)/2+20
      scaleL := 2
      scaleLwidth := 2
      scaleM := 1
      scaleMwidth := 1
      scaleS := 1
      scaleSwidth := 0
      showPeak := TRUE
      scaleRPM := 56
      scaleBoost := 58
      descripY := -40
      unitsY := 25
      dialXoffset := -1
      dialYoffset := 0
      scaleTick := $92
      scaleArc := $80
      peakAX := 92
      peakBX := 220
      peakY := 206
      digOffset := 5
      scaleBar := 40
              
    4:
      if (gauge_pos == 0) 
        CenterX := x_tiles*16/4
        CenterY := (y_tiles*16) - ((y_tiles*16-BottomMenuHeight)/4) - 10
      elseif (gauge_pos == 1)
        CenterX := x_tiles*16/4 + (x_tiles*16/2)
        CenterY := (y_tiles*16) - ((y_tiles*16-BottomMenuHeight)/4) - 10
      elseif (gauge_pos == 2)
        CenterX := x_tiles*16/4
        CenterY := (y_tiles*16) - (((y_tiles*16-BottomMenuHeight)/4)*3) - 5
      elseif (gauge_pos == 3)
        CenterX := x_tiles*16/4 + (x_tiles*16/2)
        CenterY := (y_tiles*16) - (((y_tiles*16-BottomMenuHeight)/4)*3) - 5
      scaleL := 2
      scaleLwidth := 1
      scaleM := 1
      scaleMwidth := 0
      scaleS := 1
      scaleSwidth := 0
      showPeak := FALSE
      scaleRPM := 56
      scaleBoost := 58
      descripY := -30
      unitsY := 15
      dialXoffset := -1
      dialYoffset := -10
      scaleTick := $92
      scaleArc := $80
      'peakAX := 84
      'peakBX := 212
      'peakY := 206
      digOffset := 10
      scaleBar := 20
      
  LabelAngle := $1000

{'Gauge Types
  RpmG         = 0              arc,max
  BoostG       = 1              arc,max
  ActIgnAdvG   = 2              dig              
  IgnCorrG     = 3              h bar
  DbwThrottleG = 4              v bar (0-100%)
  SpeedG       = 5              dig
  MapSelectG   = 6              dig
  IatG         = 7              arc, max
  MethFlowPctG = 8              v bar (0-100%)
  OilTempG     = 9              arc, max
  ThrottleG    = 10             v bar (0-100%)
  DmeIgnAdvG   = 11             h bar
  AtBoostLvlG  = 12             dig
  DmeCodesG    = 13             dig
  AfrBank1G    = 14             arc, max
  AfrBank2G    = 15             arc, max
  MaxTypeG     = 16
}

  Case GaugeArray[gauge_pos]
    RpmG :
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)
        gr.text(CenterX,CenterY+descripY,String("TACH"))
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)
        gr.text(CenterX,CenterY+unitsY,String("rpm"))

        'Draw labels around arc
        gr.textmode(scaleM,scaleM,6,%0101)
        Repeat I from 0 to 8
          if (I => 7)
            gr.color(2) 
          gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleRPM,LabelAngle,Lookup(I+1: @Tach0,@Tach1,@Tach2,@Tach3,@Tach4,@Tach5,@Tach6,@Tach7,@Tach8))
          LabelAngle := LabelAngle - ($1000/8) 
         
        'Draw tick marks around the arc graph
        gr.color(1) 
        ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleTick,8,$1000,0,0)
        NormalText
      else
        'Truncate RPMs to 50rpm resolution
        ActiveArray[gauge_pos] := (ActiveArray[gauge_pos]+49)/100*100 

        if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) => 50 ' New Value or Higher
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            if (ActiveArray[gauge_pos] => 7000)
              gr.colorwidth(2,scaleLwidth)
              warnon[gauge_pos] := 1
            else
              gr.colorwidth(3,scaleLwidth)  
            ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/78),0)          
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,scaleLwidth)
            ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/78),1)
            if ((ActiveArray[gauge_pos] < 7000) and (warnon[gauge_pos] == 1))
              gr.colorwidth(0,scaleLwidth)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,100,0,$1000-(($2000)/200)*0,1)
              gr.colorwidth(3,scaleLwidth)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,100,$1000,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/78),0)
              warnon[gauge_pos] := 0

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          DisplayDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX,CenterY-5,@Temp)
          DisplayDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX,CenterY-5,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]
          
      'Display Peak RPMs
      if (showPeak == TRUE)
        'if (ActiveArray[gauge_pos] > PeakArray[gauge_pos])
        if ((ActiveArray[gauge_pos] > PeakArray[gauge_pos]) or (isUpdate == FALSE))
          gr.color(3)
          gr.textmode(scaleS,scaleS,6,%1001) 'right justify
          if (gauge_pos == 0)
            gr.filledbox(peakAX,peakY,36,14)
          else
            gr.filledbox(peakBX,peakY,36,14)
          gr.colorwidth(1,scaleSwidth)
          if (gauge_pos == 0) and (isUpdate == FALSE)
            DisplayDec(PeakArray[0])
          elseif (gauge_pos == 1) and (isUpdate == FALSE)
            DisplayDec(PeakArray[1])
          else
            DisplayDec(ActiveArray[gauge_pos])          
          if (gauge_pos == 0)            
            gr.text(peakAX+6,peakY+6,String($7f))
            gr.text(peakAX+32,peakY+6,@Temp)
          else
            gr.text(peakBX+6,peakY+6,String($7f))
            gr.text(peakBX+32,peakY+6,@Temp)
          if (isUpdate)
            PeakArray[gauge_pos] := ActiveArray[gauge_pos]

    BoostG,BoostExtG :
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)
        if (GaugeArray[gauge_pos] == BoostG)
          gr.text(CenterX,CenterY+descripY,String("TMAP"))
        else
          gr.text(CenterX,CenterY+descripY,String("BOOST"))        
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)
        gr.text(CenterX,CenterY+unitsY,String("psi"))

        'Draw labels around arc
        gr.textmode(scaleM,scaleM,6,%0101)

        if (GaugeArray[gauge_pos] == BoostG)
          Repeat I from 0 to 5
            gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleBoost,scaleBoost,LabelAngle,Lookup(I+1: @Boost3,@Boost4,@Boost5,@Boost6,@Boost7,@Boost8))
            LabelAngle := LabelAngle - ($1000/5)
            'Draw tick marks around the arc graph
            gr.color(1) 
            ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleTick,5,$1000,0,0)
        else
          Repeat I from 0 to 8
            gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleBoost,scaleBoost,LabelAngle,Lookup(I+1: @Boost0,@Boost1,@Boost2,@Boost3,@Boost4,@Boost5,@Boost6,@Boost7,@Boost8))
            LabelAngle := LabelAngle - ($1000/8)
            'Draw tick marks around the arc graph
            gr.color(1) 
            ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleTick,8,$1000,0,0)

        NormalText
      else
        if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) => 10 ' New Value or Higher
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            gr.colorwidth(3,scaleLwidth)
            if (GaugeArray[gauge_pos] == BoostG)
              if (ActiveArray[gauge_pos] < 0)
                ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*0,0)  
              else
                ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/25),0)
            else
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*((ActiveArray[gauge_pos]+1470)/39),0)            
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,scaleLwidth)
            if (GaugeArray[gauge_pos] == BoostG)
              if (ActiveArray[gauge_pos] < 0)
                ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*0,1)
              else
                ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/25),1)
            else
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*((ActiveArray[gauge_pos]+1470)/39),1)            

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          FixedDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX,CenterY-5,@Temp)
          FixedDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX,CenterY-5,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]
             
      'Display Peak boost
      if (showPeak == TRUE)
        if ((ActiveArray[gauge_pos] > PeakArray[gauge_pos]) or (isUpdate == FALSE))
        'if (ActiveArray[gauge_pos] > PeakArray[gauge_pos])
          gr.color(3)
          gr.textmode(scaleS,scaleS,6,%1001) 'right justify
          'if ((ActiveArray[gauge_pos] > PeakArrayA[gauge_pos]) and (gauge_pos == 0))
          if (gauge_pos == 0)
            gr.filledbox(peakAX,peakY,36,14)
          else
            gr.filledbox(peakBX,peakY,36,14)
          gr.colorwidth(1,scaleSwidth)
          if (gauge_pos == 0) and (isUpdate == FALSE)
            FixedDec(PeakArray[0])
          elseif (gauge_pos == 1) and (isUpdate == FALSE)
            FixedDec(PeakArray[1])
          else
            FixedDec(ActiveArray[gauge_pos])
          'if ((ActiveArray[gauge_pos] > PeakArrayA[gauge_pos]) and (gauge_pos == 0))
          if (gauge_pos == 0)            
            gr.text(peakAX+7,peakY+6,String($7f))
            gr.text(peakAX+32,peakY+6,@Temp)
            'gr.vec(peakAX+8,peakY+4,$100,0,@triangle)
            'PeakArray[gauge_pos] := ActiveArray[gauge_pos]
          else
            gr.text(peakBX+7,peakY+6,String($7f))
            gr.text(peakBX+32,peakY+6,@Temp)
            'gr.vec(peakBX+8,peakY+4,$100,0,@triangle)
          if (isUpdate)
            PeakArray[gauge_pos] := ActiveArray[gauge_pos]

    IatG,OilTempG : ',CoolantTempG :
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)
        if (GaugeArray[gauge_pos] == IatG)
          gr.text(CenterX,CenterY+descripY,String("IAT"))
        'elseif (GaugeArray[gauge_pos] == CoolantTempG)
        '  gr.text(CenterX,CenterY+descripY,String("COOLANT"))
        else
          gr.text(CenterX,CenterY+descripY,String("OIL TEMP"))
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)
        gr.text(CenterX,CenterY+unitsY,String($80))
        gr.text(CenterX,CenterY+unitsY,String("  F"))

        'Draw labels around arc
        gr.textmode(scaleM,scaleM,5,%0101)
        'iat: -20 to 130 C, -4 to 266 F (253-403 raw), optimal is 75-90F, high pt is 165F so use range of 0-200F 
        'coolant: -54 to 350.600006 F (0-300 raw),  optimal is 200-212F, high pt is 117C = 242.6F so use range of 140-270F  
        'oil: 32 to 11828.299805 F (0-65535 raw), optimal is 170-260F so use range of 120-340F
        if (GaugeArray[gauge_pos] == IatG)
          gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleBoost,LabelAngle,String("0"))
          gr.color(2)
          gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleBoost,0,String("200"))          
        'elseif (GaugeArray[gauge_pos] == CoolantTempG)
        '  gr.textarc(CenterX,CenterY+dialYoffset,scaleRPM,scaleBoost,LabelAngle,String("140"))
        '  gr.color(2)
        '  gr.textarc(CenterX,CenterY+dialYoffset,scaleRPM,scaleBoost,0,String("270"))
        elseif (GaugeArray[gauge_pos] == OilTempG)
          gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleBoost,LabelAngle,String("120"))
          gr.color(2)
          gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleBoost,0,String("340"))   
         
        'Draw tick marks around the arc graph
        gr.color(1) 
        ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleTick,2,$1000,0,0)
        NormalText
      else
        if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) =>  1' New Value or Higher
          'Warning thresholds & dial division size
          ' arcDiv: (max-min)/102, arc angle 
          ' adjust: min/arcDiv, arc starting adjustment (if not 0)
          if (GaugeArray[gauge_pos] == IatG)
            threshold := 150
            'arcDiv := 1.96
            arcDiv := 2
            tempmin := 0
            tempmax := 200
            'adjust := 20.45
            adjust := 0
          'elseif (GaugeArray[gauge_pos] == CoolantTempG)
          '  threshold := 242
            'arcDiv := 1.275
          '  arcDiv := 1
          '  tempmin := 140
          '  tempmax := 270
            'adjust := 109.76
          '  adjust := 109          
          elseif (GaugeArray[gauge_pos] == OilTempG)
            threshold := 298
            'arcDiv := 2.1569
            arcDiv := 2
            tempmin := 120
            tempmax := 340
            'adjust := 55.64
            adjust := 55
           
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            if (ActiveArray[gauge_pos] => threshold)
              gr.colorwidth(2,scaleLwidth)
              warnon[gauge_pos] := 1
            else
              gr.colorwidth(3,scaleLwidth)
            if (ActiveArray[gauge_pos] > tempmax)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*102,0)
            elseif (ActiveArray[gauge_pos] < tempmin)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*0,0)
            else   
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/arcDiv-adjust),0)          
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,scaleLwidth)
            if (ActiveArray[gauge_pos] > tempmax)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*102,1)
            elseif (ActiveArray[gauge_pos] < tempmin)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*0,1)
            else   
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/arcDiv-adjust),1)
            if ((ActiveArray[gauge_pos] < threshold) and (warnon == 1))
              gr.colorwidth(0,scaleLwidth)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,100,0,$1000-(($2000)/200)*0,1)
              gr.colorwidth(3,scaleLwidth)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,100,$1000,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/arcDiv-adjust),0)
              warnon[gauge_pos] := 0

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          DisplayDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX,CenterY-5,@Temp)
          DisplayDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX,CenterY-5,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]

      'Display Peak Temp
      if (showPeak == TRUE)
        if ((ActiveArray[gauge_pos] > PeakArray[gauge_pos]) or (isUpdate == FALSE))
        'if (ActiveArray[gauge_pos] > PeakArray[gauge_pos])
          gr.color(3)
          gr.textmode(scaleS,scaleS,6,%1001) 'right justify
          'if ((ActiveArray[gauge_pos] > PeakArrayA[gauge_pos]) and (gauge_pos == 0))
          if (gauge_pos == 0)
            gr.filledbox(peakAX,peakY,36,14)
          else
            gr.filledbox(peakBX,peakY,36,14)
          gr.colorwidth(1,scaleSwidth)
          if (gauge_pos == 0) and (isUpdate == FALSE)
            DisplayDec(PeakArray[0])
          elseif (gauge_pos == 1) and (isUpdate == FALSE)
            DisplayDec(PeakArray[1])
          else
            DisplayDec(ActiveArray[gauge_pos])  
          'if ((ActiveArray[gauge_pos] > PeakArrayA[gauge_pos]) and (gauge_pos == 0))
          if (gauge_pos == 0)            
            gr.text(peakAX+7,peakY+6,String($7f))
            gr.text(peakAX+32,peakY+6,@Temp)
            'gr.vec(peakAX+8,peakY+4,$100,0,@triangle)
            'PeakArray[gauge_pos] := ActiveArray[gauge_pos]
          else
            gr.text(peakBX+7,peakY+6,String($7f))
            gr.text(peakBX+32,peakY+6,@Temp)
            'gr.vec(peakBX+8,peakY+4,$100,0,@triangle)
          if (isUpdate)
            PeakArray[gauge_pos] := ActiveArray[gauge_pos]

    AfrBank1G,AfrBank2G :
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)
        if (GaugeArray[gauge_pos] == AfrBank1G)
          gr.text(CenterX,CenterY+descripY,String("AFR1"))
        else
          gr.text(CenterX,CenterY+descripY,String("AFR2"))        
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)
        gr.text(CenterX,CenterY+unitsY,String(":1"))

        'Draw labels around arc
        gr.textmode(scaleM,scaleM,6,%0101)
        gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleBoost,LabelAngle,String("10"))
        gr.textarc(CenterX+dialXoffset,CenterY+dialYoffset,scaleRPM,scaleBoost,0,String("20"))
         
        'Draw tick marks around the arc graph
        gr.color(1) 
        ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleTick,3,$1000,0,0)
        NormalText
      else
        if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) => 10 ' New Value or Higher
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            gr.colorwidth(3,scaleLwidth)
            if (ActiveArray[gauge_pos] > 2000)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*102,0)
            elseif (ActiveArray[gauge_pos] < 1000)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*0,0)        
            else
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*((ActiveArray[gauge_pos])/10-100),0)          
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,scaleLwidth)
            if (ActiveArray[gauge_pos] > 2000)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*102,1)
            elseif (ActiveArray[gauge_pos] < 1000)
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*0,1)
            else   
              ArcDial(CenterX+dialXoffset,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*(ActiveArray[gauge_pos]/10-100),1)

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          FixedDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX,CenterY-5,@Temp)
          FixedDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX,CenterY-5,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]
    
    MapSelectG,AtBoostLvlG,DmeCodesG,SpeedG,ActIgnAdvG,IgnCorrG,DmeIgnAdvG,TimerG : 'digital style gauges
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)

        if (GaugeArray[gauge_pos] == MapSelectG)
          gr.text(CenterX,CenterY+descripY,String("MAP #"))
        elseif (GaugeArray[gauge_pos] == AtBoostLvlG)
          gr.text(CenterX,CenterY+descripY,String("AT BOOST"))
        elseif (GaugeArray[gauge_pos] == DmeCodesG)
          gr.text(CenterX,CenterY+descripY,String("DME CODE"))
        elseif (GaugeArray[gauge_pos] == SpeedG)
          gr.text(CenterX,CenterY+descripY,String("SPEED"))
        elseif (GaugeArray[gauge_pos] == ActIgnAdvG)
          gr.text(CenterX,CenterY+descripY,String("AT IGN COR"))
        elseif (GaugeArray[gauge_pos] == IgnCorrG)         
          gr.text(CenterX,CenterY+descripY,String("IGN CORR"))
        elseif (GaugeArray[gauge_pos] == DmeIgnAdvG)
          gr.text(CenterX,CenterY+descripY,String("DME IGN AD"))
        elseif (GaugeArray[gauge_pos] == TimerG)
          gr.text(CenterX,CenterY+descripY,String("TIMER"))        
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)
        if (GaugeArray[gauge_pos] == AtBoostLvlG)
          gr.text(CenterX,CenterY+unitsY+digOffset,String("psi"))
        elseif (GaugeArray[gauge_pos] == SpeedG)
          gr.text(CenterX,CenterY+unitsY+digOffset,String("mph"))
        elseif (GaugeArray[gauge_pos] == ActIgnAdvG)
          gr.text(CenterX,CenterY+unitsY+digOffset,String("deg BTDC"))
        elseif ((GaugeArray[gauge_pos] == IgnCorrG) or (GaugeArray[gauge_pos] == DmeIgnAdvG))
          gr.text(CenterX,CenterY+unitsY+digOffset,String("deg"))
        elseif (GaugeArray[gauge_pos] == TimerG)
          gr.text(CenterX,CenterY+unitsY+digOffset,String("sec"))
        'elseif (GaugeArray[gauge_pos] == DmeCodesG)
        '  gr.text(CenterX,CenterY+unitsY+digOffset,String("hex"))        
          'elseif (GaugeArray[gauge_pos] == MapSelectG) 
          '  no units for these
      else
        if (ActiveArray[gauge_pos] <> _ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.textmode(scaleL,scaleL,6,%0101)
     
          'overwrite old numbers in black
          gr.color(0)
          if ((GaugeArray[gauge_pos] == AtBoostLvlG) or (GaugeArray[gauge_pos] == ActIgnAdvG) or (GaugeArray[gauge_pos] == IgnCorrG) or (GaugeArray[gauge_pos] == DmeIgnAdvG) or (GaugeArray[gauge_pos] == TimerG) or (GaugeArray[gauge_pos] == SpeedG))
            FixedDec(_ActiveArray[gauge_pos])
          else
            DisplayDec(_ActiveArray[gauge_pos])
          gr.text(CenterX,CenterY,@Temp)
     
          'write new numbers in white        
          gr.color(1)
          if ((GaugeArray[gauge_pos] == AtBoostLvlG) or (GaugeArray[gauge_pos] == ActIgnAdvG) or (GaugeArray[gauge_pos] == IgnCorrG) or (GaugeArray[gauge_pos] == DmeIgnAdvG) or (GaugeArray[gauge_pos] == TimerG) or (GaugeArray[gauge_pos] == SpeedG))
            FixedDec(ActiveArray[gauge_pos])
          else
            DisplayDec(ActiveArray[gauge_pos])          
          gr.text(CenterX,CenterY,@Temp)
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]

    DbwThrottleG,MethFlowG : 'Half Arc Gauges
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)

        if (GaugeArray[gauge_pos] == DbwThrottleG)
          gr.text(CenterX,CenterY+descripY,String("DBW THROT"))
        else
          gr.text(CenterX,CenterY+descripY,String("METH FLOW"))
        
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)

        if (GaugeArray[gauge_pos] == DbwThrottleG)
          gr.text(CenterX+unitsY,CenterY+unitsY,String("%"))    

        'Draw labels around arc
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.textarc(CenterX+unitsY,CenterY+dialYoffset,scaleRPM,scaleRPM,LabelAngle,String("0"))
        gr.color(2)
        gr.textarc(CenterX+unitsY,CenterY+dialYoffset,scaleRPM,scaleRPM,LabelAngle/2,String("100"))
         
        'Draw tick marks around the arc graph
        gr.color(1) 
        ArcDial(CenterX+unitsY,CenterY+dialYoffset,scaleTick,2,$1000,$1000/2,0)
        NormalText
      else
        'if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) => 2 ' New Value or Higher
        if (ActiveArray[gauge_pos] <> _ActiveArray[gauge_pos])
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            gr.colorwidth(3,scaleLwidth)
            ArcDial(CenterX+unitsY,CenterY+dialYoffset,scaleArc,50,$1000,$1000-(($2000)/200)*((ActiveArray[gauge_pos])/2),0)
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,scaleLwidth)
            ArcDial(CenterX+unitsY,CenterY+dialYoffset,scaleArc,50,0,$1000-(($2000)/200)*((ActiveArray[gauge_pos])/2),1)

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          DisplayDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX+unitsY,CenterY-5,@Temp)
          DisplayDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX+unitsY,CenterY-5,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]

          'Display Peak Flow
      if ((showPeak == TRUE) and (GaugeArray[gauge_pos] == MethFlowG))
        if ((ActiveArray[gauge_pos] > PeakArray[gauge_pos]) or (isUpdate == FALSE))
        'if (ActiveArray[gauge_pos] > PeakArray[gauge_pos])
          gr.color(3)
          gr.textmode(scaleS,scaleS,6,%1001) 'right justify
          'if ((ActiveArray[gauge_pos] > PeakArrayA[gauge_pos]) and (gauge_pos == 0))
          if (gauge_pos == 0)
            gr.filledbox(peakAX,peakY,36,14)
          else
            gr.filledbox(peakBX,peakY,36,14)
          gr.colorwidth(1,scaleSwidth)
          if (gauge_pos == 0) and (isUpdate == FALSE)
            DisplayDec(PeakArray[0])
          elseif (gauge_pos == 1) and (isUpdate == FALSE)
            DisplayDec(PeakArray[1])
          else
            DisplayDec(ActiveArray[gauge_pos])  
          'if ((ActiveArray[gauge_pos] > PeakArrayA[gauge_pos]) and (gauge_pos == 0))
          if (gauge_pos == 0)            
            gr.text(peakAX+7,peakY+6,String($7f))
            gr.text(peakAX+32,peakY+6,@Temp)
            'gr.vec(peakAX+8,peakY+4,$100,0,@triangle)
            'PeakArray[gauge_pos] := ActiveArray[gauge_pos]
          else
            gr.text(peakBX+7,peakY+6,String($7f))
            gr.text(peakBX+32,peakY+6,@Temp)
            'gr.vec(peakBX+8,peakY+4,$100,0,@triangle)
          if (isUpdate)
            PeakArray[gauge_pos] := ActiveArray[gauge_pos]

{    IgnCorrG,DmeIgnAdvG : 'Horizontal Bar Gauges
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)

        if (GaugeArray[gauge_pos] == IgnCorrG)
          gr.text(CenterX,CenterY+descripY,String("IGN CORR"))
        elseif (GaugeArray[gauge_pos] == DmeIgnAdvG)
          gr.text(CenterX,CenterY+descripY,String("DME IGN ADV"))
        gr.textmode(scaleS,scaleS,6,%0101)
        gr.colorwidth(1,scaleSwidth)
        gr.text(CenterX,CenterY+unitsY-10,String("deg"))

        'Draw tick marks along the bar graph 
        BarTick(CenterX,CenterY+5,1,scaleTick,2,180)

      else
        if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) => 10 ' New Value or Higher
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            gr.colorwidth(3,0)
            gr.filledbox(CenterX-70,CenterY-scaleBar+140,CenterX+ActiveArray[gauge_pos]/100-50,scaleBar/2)
            '+/- 15.75 degrees for Ign Corr, 0-64 for DME Ign Adv 
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,0)
            gr.filledbox(CenterX+ActiveArray[gauge_pos]/100-50,CenterY-scaleBar+140,CenterX+6400/100-50,scaleBar/2)

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          FixedDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX,CenterY-5,@Temp)
          FixedDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX,CenterY-5,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]
          
    DbwThrottleG,MethFlowPctG : 'Vertical Bar Gauges
      if (isUpdate == FALSE)
        gr.textmode(scaleL,scaleL,6,%0101)
        gr.colorwidth(1,scaleMwidth)

        if (GaugeArray[gauge_pos] == DbwThrottleG)
          gr.text(CenterX,CenterY+descripY,String("DBW THROT."))
        else
          gr.text(CenterX,CenterY+descripY,String("METH FLOW"))
        gr.text(CenterX+75/scaling,CenterY-10,String("%"))

        'Draw tick marks along the bar graph
        if (scaling == 1) 
          BarTick(CenterX-35,CenterY+114,0,scaleTick,1,107)
        elseif (scaling == 2)
          BarTick(CenterX-23,CenterY+56,0,scaleTick,1,52)
        else
          BarTick(CenterX-18,CenterY+32,0,scaleTick,1,26)

      else
        if ||(ActiveArray[gauge_pos]-_ActiveArray[gauge_pos]) => 2 ' New Value or Higher
          if (ActiveArray[gauge_pos] > _ActiveArray[gauge_pos])
            'If value increases, draw color (increment bar)
            gr.colorwidth(3,0)
            gr.filledbox(CenterX-scaleBar/2,CenterY+ActiveArray[gauge_pos]/scaling+5,scaleBar,10/scaling)
          else
            'If value decreases, draw black (erase bar)
            gr.colorwidth(0,0)
            gr.filledbox(CenterX-scaleBar/2,CenterY+ActiveArray[gauge_pos]/scaling+5,scaleBar,10/scaling)

          'Update digital number
          gr.textmode(scaleL,scaleL,6,%0101)
          gr.colorwidth(0,scaleLwidth)
          DisplayDec(_ActiveArray[gauge_pos])
          gr.color(0)
          gr.text(CenterX,CenterY-10,@Temp)
          DisplayDec(ActiveArray[gauge_pos])
          gr.colorwidth(1,scaleLwidth)
          gr.text(CenterX,CenterY-10,@Temp)
          NormalText
           
          'Save new param to prev 
          _ActiveArray[gauge_pos] := ActiveArray[gauge_pos]
}

Pub InitParamArray|x

  repeat x from 0 to (MaxTypeG-1)
    _ParamArray[x] := -1
    ParamArray[x] := 0  

Pub InitActiveArray|x

  repeat x from 0 to (MaxGaugesShown-1)
    _ActiveArray[x] := -999

'Draw One Gauge Display
Pub DrawOneGauge(gauge_1)

  'Check if gauge is changing from previous one           
  if (GaugeArray[0] <> gauge_1)
    GaugeArray[0] := gauge_1
    'Reset peak recalls when gauge first drawn
    PeakArray[0] := -999
    warnon[0] := 0
    'ShowGaugeType(0,1,FALSE)
   
  ShowGaugeType(0,1,FALSE)
  InitActiveArray
    
'Draw Two Gauge Display
Pub DrawTwoGauge(gauge_1_2)|x,tempG

  'GaugeArray[0] := (gauge_1_2 >> 4)
  'GaugeArray[1] := (gauge_1_2 & $F)

  repeat x from 0 to 1
    'Check if gauge is changing from previous one
    if (x == 0)
      tempG := (gauge_1_2 >> 4)
    else
      tempG := (gauge_1_2 & $F)
           
    if (GaugeArray[x] <> tempG)
      GaugeArray[x] := tempG
      'Reset peak recalls when gauge first drawn
      PeakArray[x] := -999
      warnon[x] := 0
      'ShowGaugeType(x,2,FALSE)

  ShowGaugeType(0,2,FALSE)
  ShowGaugeType(1,2,FALSE)
  InitActiveArray
  

'Draw Four Gauge Display
Pub DrawFourGauge(gauge_1_2,gauge_3_4)|x,tempG

  repeat x from 0 to (MaxGaugesShown-1)
    'Check if gauge is changing from previous one
    if (x == 0)
      tempG := (gauge_1_2 >> 4)
    elseif (x == 1)
      tempG := (gauge_1_2 & $F)
    elseif (x == 2)
      tempG := (gauge_3_4 >> 4)
    else
      tempG := (gauge_3_4 & $F)
           
    if (GaugeArray[x] <> tempG)
      GaugeArray[x] := tempG
      'Reset peak recalls when gauge first drawn
      'PeakArrayA[x] := -999
      'PeakArrayB[x] := -999
      warnon[x] := 0
      'ShowGaugeType(x,4,FALSE)

  'Re-draw all gauges due to update of screen
  ShowGaugeType(0,4,FALSE)
  ShowGaugeType(1,4,FALSE)
  ShowGaugeType(2,4,FALSE)
  ShowGaugeType(3,4,FALSE)
  InitActiveArray

'Update All Gauge Displays
Pub UpdateGauge(count,gauge_num,new_param)

  ActiveArray[gauge_num] := new_param
  ShowGaugeType(gauge_num,count,TRUE)
  
{'Draw Six Gauge Display
Pub SixGauge1(gauge_1_2,gauge_3_4)
  '
  'g1 := (gauge_1_2 >> 4)
  'g2 := (gauge_1_2 & $F)
  'g3 := (gauge_3_4 >> 4)
  'g4 := (gauge_3_4 & $F)
  'ShowGaugeType((gauge_1_2 >> 4),0,0,6)
  'ShowGaugeType((gauge_1_2 & $F),50,50,6)
  'ShowGaugeType((gauge_3_4 >> 4),0,0,6)
  'ShowGaugeType((gauge_3_4 & $F),50,50,6)
  '
'Draw Six Gauge Display
Pub SixGauge2(gauge_5_6)
  '
  'g5 := (gauge_5_6 >> 4)
  'g6 := (gauge_5_6 & $F)
  'ShowGaugeType((gauge_5_6 >> 4),0,0,6)
  'ShowGaugeType((gauge_5_6 & $F),50,50,6)
  '

Pri DrawTwoGaugeTimer(gauge1,gauge2)|x,tempG

  repeat x from 0 to 1
    'Check if gauge is changing from previous one
    if (x == 0)
      tempG := gauge1
    else
      tempG := gauge2
           
    if (GaugeArray[x] <> tempG)
      GaugeArray[x] := tempG
      'Reset peak recalls when gauge first drawn
      'PeakArrayA[x] := -999
      'PeakArrayB[x] := -999
      warnon[x] := 0
      ShowGaugeType(x,2,FALSE)
}

'Draw TimerSetXY Display
Pub TimerSetXY(start_speed,stop_speed)

  gr.textmode(2,2,6,%0101)
  gr.colorwidth(1,2)

  DisplayDec(start_speed)
  gr.text(x_tiles*16/2-40,200,@Temp)
  gr.text(x_tiles*16/2,200,String("to"))
  DisplayDec(stop_speed)
  gr.text(x_tiles*16/2+40,200,@Temp)

  'DrawTwoGaugeTimer(SpeedG,TimerG)
  GaugeArray[0] := SpeedG
  GaugeArray[1] := TimerG
  ShowGaugeType(0,2,FALSE)
  ShowGaugeType(1,2,FALSE)

'Draw TimerSetFATS Display
Pub TimerSetFATS(start_rpm,stop_rpm)

  gr.textmode(2,2,6,%0101)
  gr.colorwidth(1,2)

  DisplayDec(start_rpm)
  gr.text(x_tiles*16/2-40,200,@Temp)
  gr.text(x_tiles*16/2,200,String("to"))
  DisplayDec(stop_rpm)
  gr.text(x_tiles*16/2+40,200,@Temp)

  GaugeArray[0] := RpmG
  GaugeArray[1] := TimerG
  ShowGaugeType(0,2,FALSE)
  ShowGaugeType(1,2,FALSE)


'Print to terminal-style window
Pub TerminalPrint(str_to_print)

  NormalText
  gr.color(1)

  IF (str_to_print == "/")
    term_x := 16
    term_xoffset := 0
    term_yoffset := 10
  ELSE
    term_xoffset := 6
    term_yoffset := 0

  term_x := term_x + term_xoffset
  IF (term_x > (x_tiles*16))
    term_x := 16
    term_xoffset := 0
    term_yoffset := 10

  term_y := term_y - term_yoffset
  IF (term_y < 32)
    term_y := (y_tiles*16)-16
    term_yoffset := 0
    gr.clear 

  if (str_to_print <> "/")
    gr.text(term_x,term_y,@str_to_print)

'Print to terminal-style window
Pub TerminalPrint2Column(str_to_print)

  NormalText
  gr.color(1)

  IF (str_to_print == "/")
    IF (column_marker == 0)
      term_x := 16
    ELSE
      term_x := 128
    term_xoffset := 0
    term_yoffset := 10
  ELSE
    term_xoffset := 6
    term_yoffset := 0

  term_x := term_x + term_xoffset
  IF (column_marker == 0)
    IF (term_x > ((x_tiles*16)/2-8))
      term_x := 16
      term_xoffset := 0
      term_yoffset := 10
  else
    IF (term_x > (x_tiles*16-16))
      term_x := 128
      term_xoffset := 0
      term_yoffset := 10

  term_y := term_y - term_yoffset
  IF (term_y < 32)
    term_y := (y_tiles*16)-16
    term_yoffset := 0
    if (column_marker == 0)
      column_marker := 1
      term_x := 128
    else
      column_marker := 0
      term_x := 16
    gr.clear 

  if (str_to_print <> "/")
    gr.text(term_x,term_y,@str_to_print)


Pub DrawBottomMenu(active_item)|x_location,y_location,spacing

  'SetColorPallet(2,CL_Black,CL_White,CL_Grey3,CL_Orange) 'Bottom menu colors
  '0= black - bg, 1= white - text, 2= grey - alt text, 3= orange - highlight

  x_location := 16
  spacing := BottomMenuHeight
  y_location := 16

  'change palette color
  SetAreaColor(0,y_tiles-2,x_tiles-1,y_tiles-1,2)
  gr.color(0)
  gr.filledbox(0,0,x_tiles*16,2*16)

  gr.color(3)
  case active_item
    ONE_GAUGE:
      gr.filledbox(0,0,spacing,spacing)
    TWO_GAUGE:
      gr.filledbox(spacing,0,spacing,spacing)
    FOUR_GAUGE:
      gr.filledbox(spacing*2,0,spacing,spacing)
    PARAM_LIST:
      gr.filledbox(spacing*3,0,spacing,spacing)
    TIMER_XY..TIMER_FATS:
      gr.filledbox(spacing*4,0,spacing,spacing)
    CONFIG_SET..VALENTINE1:
      gr.filledbox(spacing*5,0,spacing,spacing)
  'LastTab := 0 'reset so no tab is highlighted

  NormalText      
  gr.color(1)
  gr.text(x_location,y_location,String("I"))
  x_location += spacing/2
  gr.text(x_location,y_location,@tickvec)
  x_location += spacing/2
  gr.text(x_location,y_location,String("II"))
  x_location += spacing
  gr.text(x_location,y_location,String("IV"))
  x_location += spacing
  gr.text(x_location,y_location,String("List"))
  x_location += spacing
  gr.vec(x_location,y_location,$100,0,@clock)
  x_location += spacing
  gr.vec(x_location,y_location,$100,0,@wrench)
  x_location += spacing
  gr.color(3)
  gr.text(x_location,y_location,String("Map  "))
  'x_location += spacing
  'gr.text(x_location,y_location,String("    "))


Pub UpdateBottomMenuMap(map_num)

  NormalText  

  gr.color(0)
  gr.filledbox(216,0,6,2*16)

  gr.color(3)
  if ((map_num < 0) or (map_num > 9))
    gr.text(218,16,String("?"))
  else
    gr.text(218,16,Lookup((map_num+1): @Tach0,@Tach1,@Tach2,@Tach3,@Tach4,@Tach5,@Tach6,@Tach7,@Tach8,@Tach9))  

Pub UpdateBottomMenuBoost(boost_lvl)  

  NormalText
  
  gr.color(0)
  gr.filledbox(32*7,0,32,2*16)
   
  gr.color(3)
  FixedDec(boost_lvl)
  gr.text(240,16,@Temp)
  

Pub HighlightMainWindow(active_item,new_highlight)|tempdraw,temp_active

  gr.colorwidth(0,0)
  if (LastMain <> 0)
    tempdraw := LastMain
    temp_active := active_item
  else
    tempdraw := 99
    temp_active := 99

  repeat 2
    case temp_active
      ONE_GAUGE:
        gr.box(0,BottomMenuHeight,x_tiles*16,y_tiles*16-BottomMenuHeight-3)
      TWO_GAUGE:
        if (tempdraw == 10)
          gr.box(0,BottomMenuHeight,x_tiles*16/2,y_tiles*16-BottomMenuHeight-3)
        elseif (tempdraw == 11)
          gr.box(x_tiles*16/2,BottomMenuHeight,x_tiles*16/2,y_tiles*16-BottomMenuHeight-3)        
      FOUR_GAUGE:
        if (tempdraw == 10)
          gr.box(0,(y_tiles*16)-(y_tiles*16-BottomMenuHeight)/2-4,x_tiles*16/2,(y_tiles*16-BottomMenuHeight)/2+1)
        elseif (tempdraw == 11)
          gr.box(x_tiles*16/2,(y_tiles*16)-(y_tiles*16-BottomMenuHeight)/2-4,x_tiles*16/2,(y_tiles*16-BottomMenuHeight)/2+1)
        elseif (tempdraw == 12)
          gr.box(0,(y_tiles*16)-(y_tiles*16-BottomMenuHeight),x_tiles*16/2,(y_tiles*16-BottomMenuHeight)/2-3)
        elseif (tempdraw == 13)
          gr.box(x_tiles*16/2,(y_tiles*16)-(y_tiles*16-BottomMenuHeight),x_tiles*16/2,(y_tiles*16-BottomMenuHeight)/2-3)
      PARAM_LIST:
        gr.box(0,BottomMenuHeight,x_tiles*16,y_tiles*16-BottomMenuHeight-3)
      TIMER_XY..TIMER_FATS:
        if (tempdraw == 10)
          gr.box(x_tiles*16/2-63,y_tiles*16-40,45,32)
        elseif (tempdraw == 11)
          gr.box(x_tiles*16/2+17,y_tiles*16-40,45,32)
      CONFIG_SET..VALENTINE1:
        gr.box(0,BottomMenuHeight,x_tiles*16,y_tiles*16-BottomMenuHeight-3)

    if (new_highlight == 0)
      quit
    else
      tempdraw := new_highlight
      temp_active := active_item
      gr.colorwidth(3,0)    

  LastMain := new_highlight


Pub HighlightMenuWindow(active_item)|temp_active

  gr.colorwidth(0,0)
  if (LastTab <> 0)
    temp_active := active_item
  else
    temp_active := 99

  repeat 2
    case temp_active
      ONE_GAUGE:
        gr.box(0,0,BottomMenuHeight,BottomMenuHeight)
      TWO_GAUGE:
        gr.box(BottomMenuHeight,0,BottomMenuHeight,BottomMenuHeight)
      FOUR_GAUGE:
        gr.box(BottomMenuHeight*2,0,BottomMenuHeight,BottomMenuHeight)
      PARAM_LIST:
        gr.box(BottomMenuHeight*3,0,BottomMenuHeight,BottomMenuHeight)
      TIMER_XY..TIMER_FATS:
        gr.box(BottomMenuHeight*4,0,BottomMenuHeight,BottomMenuHeight)
      CONFIG_SET..VALENTINE1:
        gr.box(BottomMenuHeight*5,0,BottomMenuHeight,BottomMenuHeight)

    if (active_item == 0)
      quit
    else
      temp_active := active_item
      gr.colorwidth(1,0)    

  LastTab := active_item
  

{Pub DrawIntroSplash(datax)

  gr.clear

  'gr.colorwidth (1,16)
  'gr.pix (100,100,6, @Intro)
  'gr.copy(bitmap_base)

  gr.textmode(2,2,6,%0101)
  gr.text(CenterX,CenterY,String("iDrivino Start!"))
}  

Pub DrawOutroSplash(datax)

  'gr.clear
  'gr.textmode(2,2,6,%0101)
  'gr.text(CenterX,CenterY,String("iDrivino Exit!"))

Pub DrawBox(x,y,width,height)

  gr.colorwidth(1,0)
  gr.box(x,y,width,height)

PUB Print_SetXY(x,y)

  print_x := x
  print_y := y
  'text_color := color

PUB Print_WriteXY(str_to_print,color)

  NormalText
  gr.color(color)
  gr.text(print_x,print_y,@str_to_print)
  print_x := print_x + 6

  
PRI private_code

DAT
tvparams                long    0               'status
                        long    1               'enable
                        long    %001_0101       'pins
                        long    %0000           'mode
                        long    0               'screen
                        long    0               'colors
                        long    x_tiles         'hc
                        long    y_tiles         'vc
                        long    11              'hx               10 = normal, 20 = double horiz resolution
                        long    1               'vx                1 = normal,  2 = double vert resolution
                        long    0               'ho
                        long    0               'vo
                        long    1               'broadcast
                        long    0               'auralcog


{Tach                    word    $8000+$500 ' Position First Point                              
                        word    8               
                        word    $8000+0 ' Draw to next line
                        word    100               
                        word    $8000+$2000-$500 ' Draw to next line
                        word    8               
                        word    $8000+$2000-$500 ' Draw to next line
                        word    0               
                        word    0                

TachCtr                 word    $8000+$2000 ' Position First Point                              
                        word    100               
                        word    0                
}

'teni    long  1, 10, 100, 1_000, 10_000, 100_000, 1_000_000, 10_000_000, 100_000_000, 1_000_000_000

Tach0                   Byte "0",0        
Tach1                   Byte "1",0
Tach2                   Byte "2",0
Tach3                   Byte "3",0
Tach4                   Byte "4",0
Tach5                   Byte "5",0
Tach6                   Byte "6",0
Tach7                   Byte "7",0
Tach8                   Byte "8",0
Tach9                   Byte "9",0

Boost0                   Byte "-15",0        
Boost1                   Byte "-10",0
Boost2                   Byte "-5",0
Boost3                   Byte "0",0
Boost4                   Byte "5",0
Boost5                   Byte "10",0
Boost6                   Byte "15",0
Boost7                   Byte "20",0
Boost8                   Byte "25",0

{num_of_params = 16;
  procede_array[0] = PROCEDE_RPM;
  procede_array[1] = PROCEDE_BOOST;
  procede_array[2] = PROCEDE_ACT_IGN_ADV;
  procede_array[3] = PROCEDE_IGN_CORR;
  procede_array[4] = PROCEDE_DBW_THROTTLE;
  procede_array[5] = PROCEDE_SPEED;
  procede_array[6] = PROCEDE_MAP_SELECT;
  procede_array[7] = PROCEDE_IAT;
  procede_array[8] = PROCEDE_COOLANT_TEMP;
  procede_array[9] = PROCEDE_OIL_TEMP;
  procede_array[10] = PROCEDE_THROTTLE;
  procede_array[11] = PROCEDE_DME_IGN_ADV;
  procede_array[12] = PROCEDE_AT_BOOST_LVL;
  procede_array[13] = PROCEDE_DME_CODES;
  procede_array[14] = PROCEDE_AFR_BANK1;
  procede_array[15] = PROCEDE_AFR_BANK2;
}

param_string1           byte "Engine Speed",0
param_string2           byte "Boost",0
param_string3           byte "Actual Ign Adv",0
param_string4           byte "Ign Correction",0
param_string5           byte "DBW Throttle",0
param_string6           byte "Road Speed",0
param_string7           byte "Map Selection",0
param_string8           byte "Intake Air Temp",0
param_string9           byte "Meth Flow Pct",0
param_string10          byte "Oil Temp",0
param_string11          byte "DME Ign Adv",0
param_string12          byte "Autotune Boost",0
param_string13          byte "DME Codes",0
param_string14          byte "AFR Bank 1",0
param_string15          byte "AFR Bank 2",0
ParamListArray          word  @param_string1,@param_string2,@param_string3,@param_string4,@param_string5,@param_string6,@param_string7,@param_string8,@param_string9,@param_string10,@param_string11,@param_string12,@param_string13,@param_string14,@param_string15,0                    

param_label1            byte "RPM",0
param_label2            byte "psi",0
param_label3            byte "deg BTDC",0
param_label4            byte "deg",0
param_label5            byte "%",0
param_label6            byte "MPH",0
param_label7            byte "#",0
param_label8            byte "deg F",0
param_label9            byte "%",0
param_label10           byte "deg F",0
param_label11           byte "deg BTDC",0
param_label12           byte "psi",0
param_label13           byte " ",0
param_label14           byte ":1",0
param_label15           byte ":1",0
ParamLabelArray         word @param_label1,@param_label2,@param_label3,@param_label4,@param_label5,@param_label6,@param_label7,@param_label8,@param_label9,@param_label10,@param_label11,@param_label12,@param_label13,@param_label14,@param_label15,0
    
{pointer                 word    $4000
                        word    0
                        word    $4000
                        word    75
                        word    $8000+$2000/12
                        word    10
                        word    $8000
                        word    0
                        word    $4000
                        word    75
                        word    $8000+($2000*11)/12
                        word    10
                        word    $8000
                        word    0
                        word    0
}
'Vector Building Program at:
'http://forums.parallax.com/showthread.php?130639-Simultaneous-VGA-and-composite
tickvec                 word    $4000
                        word    75
                        word    $8000
                        word    85
                        word    0
                                      
tickvec2                word    $4000
                        word    74
                        word    $8000
                        word    86
                        word    0


wrench          word    $4000+1234
                word    11
                word    $8000+1515
                word    10
                word    $8000+1783
                word    7
                word    $8000+1616
                word    4
                word    $8000+4910
                word    11
                word    $8000+5341
                word    11
                word    $8000+407
                word    4
                word    $8000+250
                word    7
                word    $8000+522
                word    10
                word    $8000+803
                word    11
                word    $8000+697
                word    8
                word    $8000+1013
                word    6
                word    $8000+1336
                word    8
                word    $8000+1234
                word    11
                word    0

clock           word    $4000+2364
                word    10
                word    $4000+1723
                word    10
                word    $4000+1274
                word    9
                word    $4000+760
                word    9
                word    $4000+314
                word    10
                word    $4000+7869
                word    10
                word    $4000+7424
                word    9
                word    $4000+6912
                word    9
                word    $4000+6467
                word    10
                word    $4000+5830
                word    10
                word    $4000+5384
                word    9
                word    $4000+4870
                word    9
                word    $4000+4421
                word    10
                word    $4000+3780
                word    10
                word    $4000+3331
                word    9
                word    $4000+2813
                word    9
                word    $4000+7168
                word    0
                word    $8000+2044
                word    10
                word    $4000+7168
                word    0
                word    $8000+8186
                word    7
                word    0

{triangle        word    $4000+2044
                word    5
                word    $8000+4520
                word    5
                word    $8000+7770
                word    5
                word    $8000+2044
                word    5
                word    0}


{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}