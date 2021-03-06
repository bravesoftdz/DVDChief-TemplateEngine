// DVDChief Template Engine Version 1.0.0 for Delphi XE/XE2/XE3
//
// SOFTWARE CAN NOT BE USED IN ANY HOME INVENTORY OR CATALOGING SOFTWARE
// (FREEWARE OR SHAREWARE) WITHOUT OUR WRITTEN PERMISSION
//
// The contents of this file are subject to the GNU General Public License
// You may redistribute this library, use and/or modify it under the terms of the
// GNU Lesser General Public License as published by the Free Software Foundation;
// either version 2.1 of the License, or (at your option) any later version.
// You may obtain a copy of the GPL at http://www.gnu.org/copyleft/.
//
// Alternatively, you may redistribute this library, use and/or modify it under the terms of the
// Mozilla Public License Version 1.1 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis,
// WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
// specific language governing rights and limitations under the License.
//
// The initial developer of the original code is Adit Software
// written by Denis Sletkov (dvd@dvdchief.com, dvdchief.com/delphi).

{$WARN SYMBOL_DEPRECATED OFF}

unit TemplateEngine;

{$J-}    //Writeable typed constants off
{$H+}    //Long strings used
{$P+}    //Open String Parameters used
{$T-}    //Generate untyped pointer
{$X+}    //Extended syntax on
{$B-}    //Boolean short-circuit evaluation
{$O+}    //Optimization on
{$R-}    //Range checking off
// make it work for Android
// (have no time to revise strings indexing ;)
{$ZEROBASEDSTRINGS OFF}
{.$DEFINE SMARTYDEBUG}

interface

uses
  Classes, SysUtils, StrUtils, DateUtils, Variants,
  Character, Generics.Defaults, Generics.Collections;

type
	ESmartyException = class (Exception)
  end;

  TTemplateAction = class;
  TForEachOutputAction = class;
  TOperation = class;
  TSmartyEngine = class;

	//record for DateLoose format
  TDateRecord = packed record
  	Year: word;         //0 means undefine
    Month, Day: byte;
    function GetVariant: Variant;
    procedure SetVariant(AValue: Variant);
  end;

  TVariableType = (vtNull,               //Not defined variable, error in evaluation
								   vtBoolean,
                   vtInteger,            //Integer variable
                   vtFloat,              //Float variable
                   vtDateStrict,         //DateStrict variable TDate
                   vtDateLoose,          //DateLoose variable for fuzzy date
                   vtDateTime,           //DateTime variable
    							 vtString,             //string variable
                   vtArray               //Associate Array
                   );
(*
	COMPARE MATRIX

               NULL    BOOL    INT    FLOAT    DATE    DLOOSE    DTIME     STRING   ARRAY
  NULL == FALSE BOOL   BOOL    BOOL   BOOL     BOOL     BOOL      BOOL      BOOL     BOOL
  BOOL          *      BOOL    BOOL   BOOL     BOOL     BOOL      BOOL      BOOL     BOOL
  INT           *       *      INT    FLOAT    INT     DLOOSE    FLOAT      FLOAT
  FLOAT         *       *       *     FLOAT    FLOAT   DLOOSE    FLOAT      FLOAT
  DATE          *       *       *      *       DATE    DLOOSE    DTIME      DATE
  DLOOSE        *       *       *      *        *      DLOOSE    DLOOSE    DLOOSE
  DTIME         *       *       *      *        *         *      DTIME      DTIME
  STRING        *       *       *      *        *         *        *       STRING
  ARRAY         *       *       *      *        *         *        *         *


*)


  TVariableTypes = set of TVariableType;

  TCompareOperation = (coEq, coNeq, coGt, coLt, coGte, coLte, coSEq);

  TBinaryOperation = (voAdd, voSubtract, voMultiply,     //IntFloatOps
                      voDivide,                          //FloatOps
                      voIntDivide, voModulus,            //IntOps
                      voShl, voShr,
                      voAnd, voOr, voXor                 //LogicalIntOps
                      );

  TVariableRelatioship = (vrGreaterThan, vrEqual, vrLessThan);

  //variable record for store variable

  PVariableRecord = ^TVariableRecord;
  TVariableRecord = packed record
  public
    VarType: TVariableType;

    procedure Finalize;
    function Clone: TVariableRecord;
    function IsNull: boolean;
    function IsEmpty: boolean;
    function IsArray: boolean;

    function IsBoolean: boolean;
    function IsInteger: boolean;
    function IsFloat: boolean;
    function IsNumber: boolean;
    function IsDateStrict: boolean;
    function IsDateLoose: boolean;
    function IsDateTime: boolean;
    function IsDate: boolean;
    function IsString: boolean;

    class function Null: TVariableRecord; static;
    class function AsInteger(AValue: integer; ANullValue: integer = 0): TVariableRecord; static;
    class function AsFloat(AValue: double; ANullValue: double = 0): TVariableRecord; static;
    class function AsString(AValue: string; ANullValue: string = ''): TVariableRecord; static;
    class function AsDateRecord(AValue: TDateRecord): TVariableRecord; static;
    procedure SetNull;
    procedure SetBool(AValue: boolean);
    procedure SetInt(AValue: integer);
    procedure SetFloat(Avalue: double);
    procedure SetString(AValue: string);
    procedure SetArrayLength(AValue: integer; AReference: TObject = nil; AInit: boolean = false);
    procedure SetArrayItem(AIndex: integer; AKey: string; AValue: TVariableRecord);
    procedure SetArrayItemQ(AIndex: integer; AKey: string; AValue: TVariableRecord);

  	function ToBool: boolean;
    function ToInt: integer;
    function ToFloat: double;
    function ToString: string;
    function CanConvertToLogical(out Value: boolean): boolean;
    function CanConvertToInt(out Value: integer): boolean;
    function CanConvertToFloat(out Value: double): boolean;
    class function DoCompareRelationship(ALeft, ARight: TVariableRecord;
    	AOperation: TCompareOperation): TVariableRelatioship; static;
    class function DoCompare(ALeft, ARight: TVariableRecord;
    	AOperation: TCompareOperation): boolean; static;
    class function DoIntFloatOp(ALeft, ARight: TVariableRecord;
    	AOperation: TBinaryOperation): TVariableRecord; static;
    class function DoFloatOp(ALeft, ARight: TVariableRecord;
    	AOperation: TBinaryOperation): TVariableRecord; static;
		class function DoIntOp(ALeft, ARight: TVariableRecord;
			AOperation: TBinaryOperation): TVariableRecord; static;
    class function DoIntNot(ARight: TVariableRecord): TVariableRecord; static;
		class function DoLogicalOp(ALeft, ARight: TVariableRecord;
			AOperation: TBinaryOperation): TVariableRecord; static;
		class function DoLogicalNot(ARight: TVariableRecord): TVariableRecord; static;

    class operator Implicit(AValue: boolean): TVariableRecord;
    class operator Implicit(AValue: integer): TVariableRecord;
    class operator Implicit(AValue: double): TVariableRecord;
    class operator Implicit(AValue: extended): TVariableRecord;
    class operator Implicit(AValue: TDate): TVariableRecord;
    class operator Implicit(AValue: TDateRecord): TVariableRecord;
    class operator Implicit(AValue: TDateTime): TVariableRecord;
    class operator Implicit(AValue: string): TVariableRecord;

    class operator Implicit(ARecord: TVariableRecord): boolean;
    class operator Implicit(ARecord: TVariableRecord): integer;
    class operator Implicit(ARecord: TVariableRecord): double;
    class operator Implicit(ARecord: TVariableRecord): string;

    class operator Add(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator Subtract(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator Multiply(ALeft, ARight: TVariableRecord): TVariableRecord;
    class operator Divide(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator IntDivide(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator Modulus(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator LeftShift(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator RightShift(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator LogicalAnd(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator LogicalOr(ALeft, ARight: TVariableRecord): TVariableRecord;
		class operator LogicalXor(ALeft, ARight: TVariableRecord): TVariableRecord;

    case TVariableType of
    	vtNull:        ();
      vtBoolean:  	 (BValue: boolean);
      vtInteger:  	 (IValue: integer);
      vtFloat:    	 (FValue: double);
      vtDateStrict:  (DSValue: TDate);
      vtDateLoose:   (DLValue: TDateRecord);
      vtDateTime: 	 (DTValue: TDateTime);
      vtString:   	 (SValue: pointer);
      vtArray:       (AValue: pointer);  //PVariableArray
  end;

  TVarModifierProc = reference to procedure(const Variable: TVariableRecord);

  TVariableArrayItem = packed record
    Key: pointer;
    Item: TVariableRecord;
  end;

  PVariableArrayData = ^TVariableArrayData;
  TVariableArrayData = array [0..0] of TVariableArrayItem;

  PVariableArray = ^TVariableArray;
  TVariableArray = packed record
  	Count: integer;
    Reference: TObject;
    Data: PVariableArrayData;
  end;

  //Variable structure

  TVariablePartType = (vptValue, vptIndex);

  TVariablePart = record
    PartType: TVariablePartType;

    procedure Finalize;
    function Clone: TVariablePart;
    class operator Implicit(AValue: integer): TVariablePart;
    class operator Implicit(AValue: string): TVariablePart;
    class operator Implicit(APart: TVariablePart): integer;
    class operator Implicit(APart: TVariablePart): string;

    case TVariablePartType of
    	vptValue: (SValue: pointer);
      vptIndex: (IValue: integer);
  end;

  TVarList = class (TList<TVariablePart>)
  public
  	function Clone: TVarList;
  	procedure Finalize;
    procedure DeleteElement(Index: integer);
    procedure AddArrayPrefix(AVariable: TVarList; Index: integer);
    function IsSimpleVariable(out VarName: string): boolean;
    function CheckTopLevel(const AName: string): boolean;
    function IsTopValueLevel(out AName: string): boolean;
  end;

  //Register Namespaces:
  // smarty - system variables

  TNamespaceProvider = class
    class function GetName: string; virtual; abstract;     //Get Namespace Name
    class function IsIndexSupported: boolean; virtual; abstract;
    class function UseCache: boolean; virtual; abstract;
    procedure GetIndexProperties(var AMin, AMax: integer); virtual; abstract;
    function GetVariable(AIndex: integer;
    	AVarName: string): TVariableRecord; virtual; abstract;
  end;

  TForEachData = class
  	Name: string;
    InForEach: boolean;
    ItemVarName, KeyVarName: string;
    Iteration: integer;   //from 1 to Count
    First: boolean;
    Last: boolean;
    Show: boolean;
    Total: integer;
    IsNamespace: boolean;
    Namespace: TNamespaceProvider;
    MinIndex: integer;
    VarData: PVariableArray;
  end;

  TForEachList = class (TList<TForEachData>)
  private
  	CurrentRecords: TList<integer>; // FI:C107
    procedure EnterForEach(AList: TForEachData);
    procedure ExitForEach;
    function InForEach: boolean;
    function FindItemRecord(const AItemName: string; out ARecord: TForEachData): boolean;
		function FindKeyRecord(const AKeyName: string; out ARecord: TForEachData): boolean;
  public
    constructor Create;
    destructor Destroy; override;
  	function FindRecord(const AName: string; out ARecord: TForEachData): boolean;
  end;

  TCaptureCache = record
    VariableName: string;            //variable name
    VariableValue: PVariableRecord;  //variable value
  end;

  TCaptureArrayItem = class
  private
    IsActive: boolean; // FI:C107
    ItemName: string; // FI:C107
    Index: integer; // FI:C107
    VarData: PVariableArray; // FI:C107
    procedure Enter(const AName: string; AIndex: integer; AVarData: PVariableArray);
    procedure IncIndex;
    procedure Exit;
    function IsItemName(const AName: string): boolean;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  //smarty provider
  TSmartyProvider = class (TNamespaceProvider)
  private
  	FEngine: TSmartyEngine;
    FCaptureCache: TList<TCaptureCache>;
  	FForEachList: TForEachList;
    FActiveCapture: TCaptureArrayItem;
    procedure ClearCaptureCache;
    function FindCaptureItem(const AName: string; var Cache: TCaptureCache): boolean;
    procedure SetCaptureItem(const AName: string; VariableValue: TVariableRecord);
    procedure RemoveCaptureItem(const AName: string);
  public
  	constructor Create(AEngine: TSmartyEngine);
    destructor Destroy; override;
    class function GetName: string; override;     //Get Namespace Name
    class function IsIndexSupported: boolean; override;
    class function UseCache: boolean; override;
    procedure GetIndexProperties(var AMin, AMax: integer); override;
    function GetVariable(AIndex: integer; AVarName: string): TVariableRecord; override;
  	function GetSmartyVariable(const AVarName: string; AVarDetails: TVarList;
    	var NeedFinalize: boolean): TVariableRecord;
    function GetDetachVariable(const AVarName: string; AVarDetails: TVarList;
    	var NeedFinalize: boolean): TVariableRecord;
  end;

  //Variable modifier

  TVariableModifierClass = class of TVariableModifier;

  TVariableModifier = class
  protected
  	class function CheckParams(AModifier: TVariableModifierClass;
    	AParams: TStringList;	AMin, AMax: integer): boolean;
    class function SetParam(AParams: TStringList; AIndex: integer;
    	var Value: string): boolean;
  public
  	class function GetName: string; virtual; abstract;
    class function CheckInputParams(AParams: TStringList): boolean; virtual; abstract;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); virtual; abstract;
    class procedure ModifyVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); virtual;
  end;

  TCapitalizeModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TCatModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TTrimModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TCountCharactersModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TCountParagraphsModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TCountWordsModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TDefaultModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  THTMLEncodeModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  THTMLEncodeAllModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TXMLEncodeModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TFileEncodeModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TDateFormatModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TFloatFormatModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TLowerModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TUpperModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TNl2BrModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TTruncateModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TStripModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TSpacifyModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TWordwrapModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TIndentModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TReplaceModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;

  TStripTagsModifier = class (TVariableModifier)
  	class function GetName: string; override;
    class function CheckInputParams(AParams: TStringList): boolean; override;
		class procedure ModVariable(const AVariable: TVariableRecord;
    	AParams: TStringList); override;
  end;


  //Functions

  TSmartyFunctionClass = class of TSmartyFunction;

  TSmartyFunction = class
  protected
    class function IsParam(Index: integer; AParams: array of TVariableRecord;
    	var Param: TVariableRecord): boolean;
    class function GetParam(Index: integer; AParams: array of TVariableRecord): TVariableRecord;
  public
  	class function GetName: string; virtual; abstract;
    class function CheckParams(AParamsCount: integer): boolean; virtual; abstract;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; virtual; abstract;
    class function EvaluateFunction(AParams: array of TVariableRecord): TVariableRecord; virtual;
  end;

  //Is... functions

  TIsNullFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsEmptyFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsBooleanFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsIntegerFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsFloatFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsNumberFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsDateStrictFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsDateLooseFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsDateTimeFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsDateFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsStringFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIsArrayFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TArrayLengthFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TArrayIndexFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TArrayKeyFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TCountFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  //String Functions

  TEchoFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TPrintFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  THTMLEncodeFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  THTMLEncodeAllFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TXMLEncodeFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TFileEncodeFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TTrimFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TTruncateFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TStripFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TStripTagsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TSpacifyFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TWordwrapFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TIndentFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TCapitalizeFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TCountCharactersFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TCountWordsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TCountParagraphsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TUpperCaseFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TLowerCaseFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TResemblesFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TContainsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TStartsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TEndsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TReplaceFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  //string float_format(float $float, string $format = "")
  TFloatFormatFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  //mixed ifthen(bool $condition, mixed $tcond, mixed $fcond)
  TIfThenFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  //DateTime Functions

  TDateFormatFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TFullYearsFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TYearOfFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TMonthOfFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;

  TDayOfFunction = class (TSmartyFunction)
  	class function GetName: string; override;
    class function CheckParams(AParamsCount: integer): boolean; override;
    class function Evaluate(AParams: array of TVariableRecord): TVariableRecord; override;
  end;


  TTemplateActionType = (tatRawOutput, tatVariableOutput, tatFuncOutput,
  	tatIf, tatForEach, tatCaptureArray, tatReleaseArray, tatAssign, tatRelease);

  TNestAction = (naNone, naIf, naForEach);

  TTemplateActions = class (TObjectList<TTemplateAction>)
    function Execute: string;
  end;

  TTemplateAction = class
  private
  	FEngine: TSmartyEngine;
    FActionType: TTemplateActionType;
  public
    property ActionType: TTemplateActionType read FActionType;

    constructor Create(AEngine: TSmartyEngine); virtual;
    function Execute: string; virtual; abstract;
    class function IsComment(var ACommand: string): boolean;
		class function IsTag(const ATag: string; const ACommand: string;
	 		AOnlyTag: boolean = false): boolean;
    class function IsTagAndGetCommand(const ATag: string;
    	var ACommand: string): boolean;
    class function IsExitCommand(const ACommand: string;
    	ABreakAction: TNestAction): boolean;
    class function ParseFunction(ACommand: string): TStringList;
    class procedure CheckFunction(ACommand: TStringList;
    	AValid: array of string);
    class function GetAttributeValue(ACommand: TStringList; const AAtribute: string;
    	const ADefault: string = ''): string;
    class procedure ExtractFunctionItem(ACommand: TStringList; Index: integer;
    	var Name, Value: string);
    class procedure ParseVariable(AVariable: string; AVarList: TVarList);
		class procedure GetVariableProperties(AEngine: TSmartyEngine;
			const AVariable: string; var Namespace: TNamespaceProvider;
      var Index: integer; var VarName: string; var AVarList: TVarList);
    class function IsAction(AEngine: TSmartyEngine; ACommand: string;
    	var AAction: TTemplateAction): boolean; virtual;
  end;

  TRawOutputAction = class (TTemplateAction)
  private
    FOutput: string;
  public
    property Output: string read FOutput;

    constructor Create(AEngine: TSmartyEngine); override;
    constructor CreateOutput(AEngine: TSmartyEngine; const AOutput: string);
    function Execute: string; override;
		class function IsAction(AEngine: TSmartyEngine;	ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TModifierAction = class
  private
    FModifier: TVariableModifierClass;
    FParams: TStringList;
  public
  	constructor Create;
    destructor Destroy; override;
  end;

  TVariableOutputAction = class (TTemplateAction)
  private
  	FNamespace: TNamespaceProvider;
    FIndex: integer;
    FVarName: string;
    FVarDetails: TVarList;
    FModifiers: TObjectList<TModifierAction>;
    procedure SetVariable(AEngine: TSmartyEngine; const AVariable: string);
  public
    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine;
    	ACommand: string; var AAction: TTemplateAction): boolean; override;
  end;

  TFuncOutputAction = class (TTemplateAction)
  private
  	FOperation: TOperation;
    FModifiers: TObjectList<TModifierAction>;
  public
    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine;
    	ACommand: string; var AAction: TTemplateAction): boolean; override;
  end;

  TOperator = (opEq,      //eq, =
               opNeq,     //ne, neq, !=, <>
               opGt,      //gt, >
               opLt,      //lt, <
               opGte,     //gte, ge, >=
               opLte,     //lte, le, <=
               opSEq,     //seq, ==

               opAdd,     //+
               opSub,     //-
               opMply,    //*
               opDivide,  // /
               opMod,     //mod, %
               opDiv,     //div, \
               opShl,     //shl, <<
               opShr,     //shr, >>

               opLogicalNot,     //not, !
               opLogicalAnd,     //and, &&
               opLogicalOr,      //or, ||

               opBitwiseNot,     //~
               opBitwiseAnd,     //bitand, &
               opBitwiseOr,      //bitor, |
               opBitwiseXor      //xor, ^
               );

  TOperation = class
  	constructor Create; virtual;
  	function Evaluate(AEngine: TSmartyEngine; var NeedFinalize: boolean): TVariableRecord; virtual; abstract;
    class function Parse(AEngine: TSmartyEngine; S: string): TOperation;
    {$IFDEF SMARTYDEBUG} function AsString: string; virtual; abstract; {$ENDIF}
  end;

  TOperationList = class (TObjectList<TOperation>)
  end;

  TOpVariable = class (TOperation)
  private
  	FNamespace: TNamespaceProvider;
    FIndex: integer;
    FVarName: string;
    FVarDetails: TVarList;
  public
  	constructor Create; override;
    destructor Destroy; override;
    function Evaluate(AEngine: TSmartyEngine;
    	var NeedFinalize: boolean): TVariableRecord; override;
    {$IFDEF SMARTYDEBUG} function AsString: string; override; {$ENDIF}
  end;

  TOpConst = class (TOperation)
  private
  	FValue: TVariableRecord;
  public
  	constructor Create; override;
    destructor Destroy; override;
    function Evaluate(AEngine: TSmartyEngine;
    	var NeedFinalize: boolean): TVariableRecord; override;
		{$IFDEF SMARTYDEBUG} function AsString: string; override; {$ENDIF}
  end;

  TOpFunction = class (TOperation)
  private
  	FFuncClass: TSmartyFunctionClass;
    FParams: TOperationList;
  public
  	constructor Create; override;
    destructor Destroy; override;
    function Evaluate(AEngine: TSmartyEngine;
    	var NeedFinalize: boolean): TVariableRecord; override;
		{$IFDEF SMARTYDEBUG} function AsString: string; override; {$ENDIF}
  end;

  TOpOperator = class (TOperation)
  private
  	FOperator: TOperator;
    FLeftOp, FRightOp: TOperation;
  public
  	constructor Create; override;
    destructor Destroy; override;
    function Evaluate(AEngine: TSmartyEngine;
    	var NeedFinalize: boolean): TVariableRecord; override;
		{$IFDEF SMARTYDEBUG} function AsString: string; override; {$ENDIF}
  end;


  TIfType = (ifSimple, ifDef, ifNDef, ifEmpty, ifNEmpty);

  TIfCondition = class
  private
  	FEngine: TSmartyEngine;
  	FIfType: TIfType;
  public
  	property IfType: TIfType read FIfType;
    function Evaluate: boolean; virtual; abstract;
    constructor Create(AEngine: TSmartyEngine); virtual;
  end;

  TSimpleIf = class (TIfCondition)
  private
  	FOperation: TOperation;
  public
    constructor Create(AEngine: TSmartyEngine); override;
    constructor CreateOperation(AEngine: TSmartyEngine; const AExpr: string);
    destructor Destroy; override;
   	function Evaluate: boolean; override;
  end;

  TVariableIf = class (TIfCondition)
  private
  	FNamespace: TNamespaceProvider;
    FIndex: integer;
    FVarName: string;
    FVarDetails: TVarList;
    procedure SetVariable(AEngine: TSmartyEngine; AVariable: string);
  public
    constructor Create(AEngine: TSmartyEngine); override;
    constructor CreateIf(AEngine: TSmartyEngine; AType: TIfType);
    destructor Destroy; override;
    function Evaluate: boolean; override;
  end;

  TElseIfAction = class
  private
  	FCondition: TIfCondition;
    FActions: TTemplateActions;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TElseIfActions = class(TObjectList<TElseIfAction>)
  end;

  TIfOutputAction = class (TTemplateAction)
  private
  	FCondition: TIfCondition;
    FThenActions, FElseActions: TTemplateActions;
    FElseIfActions: TElseIfActions;
    function ContinueIf(AEngine: TSmartyEngine; ACommand: string;
    	var AState: integer; var AActions: TTemplateActions): boolean;
  public
    property ThenActions: TTemplateActions read FThenActions;
    property ElseActions: TTemplateActions read FElseActions;
    property ElseIfActions: TElseIfActions read FElseIfActions;

    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine;	ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TForEachOutputAction = class (TTemplateAction)
  private
    FNamespaceBased: boolean;
  	FNamespace: TNamespaceProvider;
    FIndex: integer;
    FVarName: string;
    FVarDetails: TVarList;
    FForEachName: string;
    FVariableName: string;
    FAssocName: string;
    FMaxItems: integer;

    FBaseActions: TTemplateActions;
    FElseActions: TTemplateActions;
    function ContinueForEach(AEngine: TSmartyEngine; ACommand: string;
    	var AState: integer; var AActions: TTemplateActions): boolean;
  public
    property NamespaceBased: boolean read FNamespaceBased;
    property VarDetails: TVarList read FVarDetails;
    property ForEachName: string read FForEachName;
    property VariableName: string read FVariableName;
    property AssocName: string read FAssocName;
    property BaseActions: TTemplateActions read FBaseActions;
    property ElseActions: TTemplateActions read FElseActions;

    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine; ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TCaptureArrayAction = class (TTemplateAction)
  private
  	FNamespace: TNamespaceProvider;
    FIndex: integer;
    FVarName: string;
    FVarDetails: TVarList;
    FItemName: string;
    FVariableName: string;
    FFilter: TOperation;
  public
    property VarDetails: TVarList read FVarDetails;

    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine; ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TReleaseArrayAction = class (TTemplateAction)
  private
    FVariableName: string;
  public
    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine; ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TAssignAction = class (TTemplateAction)
  private
    FVariableName: string;
    FValue: TOperation;
  public
    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine; ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TReleaseAction = class (TTemplateAction)
  private
    FVariableName: string;
  public
    constructor Create(AEngine: TSmartyEngine); override;
    destructor Destroy; override;
    function Execute: string; override;
    class function IsAction(AEngine: TSmartyEngine; ACommand: string;
    	var AAction: TTemplateAction): boolean; override;
  end;

  TVariableCache = record
  	Namespace: TNamespaceProvider;   //nil, if not namespace
    Index: integer;                  //-1, if no index
    VariableName: string;            //variable name
    VariableValue: PVariableRecord;  //variable value
  end;

  TClassRecord = class
  protected
    FClass: TClass;
  end;

  TCustomClassList = class(TStringList)
  public
    constructor Create; reintroduce;

    procedure Add(const AName: string; AClass: TClass); reintroduce;
    function GetClass(Index: Integer): TClass;
  end;

  TModifierList = class(TCustomClassList)
  public
    procedure Add(AModifier: TVariableModifierClass); reintroduce;
    function GetModifier(Index: Integer): TVariableModifierClass;
  end;

  TFunctionList = class(TCustomClassList)
  public
    procedure Add(AFunction: TSmartyFunctionClass); reintroduce;
    function GetFunction(Index: Integer): TSmartyFunctionClass;
  end;

  TNamespaceList = class(TCustomClassList)
  public
    procedure Add(ANamespace: TNamespaceProvider); reintroduce;
  end;

  TSmartyInfoProvider = class
  private
    //modifiers
    FModifiers: TModifierList;

    //function
    FFunctions: TFunctionList;

  	procedure Init;
  public
  	constructor Create;
    destructor Destroy; override;
    procedure AddModifier(AModifier: TVariableModifierClass);
    procedure AddFunction(AFunction: TSmartyFunctionClass);
    procedure DeleteFunction(AFunction: TSmartyFunctionClass);
  end;

  TSmartyEngine = class
  private
  	FCompiled: boolean;
    FActions: TTemplateActions;

    //namespaces
    FNamespaces: TNamespaceList;
    FSmartyNamespace: TSmartyProvider;

    FIsCache: boolean;
    FVarCache: TList<TVariableCache>;

    //error handling
    FSilentMode: boolean;
    FErrors: TStringList;
    FAutoHTMLEncode: boolean;
    FAllowEspacesInStrings: boolean;

    //template properties
    FTemplateFolder: string;

    procedure Init;
    function GetVariable(const ANamespace: TNamespaceProvider; AIndex: integer;
    	const AVariableName: string; ADetails: TVarList; var NeedFinalize: boolean): TVariableRecord;
    function GetVariableDetails(AVariable: TVariableRecord; ADetails: TVarList): TVariableRecord;
		function IsFunction(ACommand: string; var Func: TSmartyFunctionClass;
			var Params: string; var Modifiers: string): boolean;
    function GetFunction(const AFunction: string): TSmartyFunctionClass;
    procedure SetIsCache(Value: boolean);
  public
  	constructor Create;
    destructor Destroy; override;
    function Compile(const ADocument: string; var Errors: TStringList): boolean;
    function Execute: string;
    procedure ClearCache; overload;
    procedure ClearCache(ANamespace: TNamespaceProvider); overload;

    procedure AddNamespace(ANamespace: TNamespaceProvider);
    procedure DeleteNamespace(ANamespace: TNamespaceProvider);

    property Compiled: boolean read FCompiled;
    property SilentMode: boolean read FSilentMode write FSilentMode;
    property Errors: TStringList read FErrors;
    property AutoHTMLEncode: boolean read FAutoHTMLEncode write FAutoHTMLEncode;
    property AllowEspacesInStrings: boolean read FAllowEspacesInStrings write FAllowEspacesInStrings;
    property IsCache: boolean read FIsCache write SetIsCache;
    property TemplateFolder: string read FTemplateFolder write FTemplateFolder;
  end;

(* Smarty template engine syntax

	Variable syntax
  $namespace.variablename[0].otherpart

	{literal} ... {/literal} - skip part of Templates as is
  {ldelim} - symbol {
  {rdelim} - symbol }

  {* comment *}            - comment in template
  { $namespace.variable | modifier:"param1":"param2" | modifier } - put variable


  { ifdef $namespace.var }
  { ifndef $namespace.var }
  { ifempty $namespace.var }
  { ifnempry $namespace.var }

  { else }
  { elseifdef $namespace.var }
  { elseifndef $namespace.var }
  { elseifempty $namespace.var }
  { elseifnempry $namespace.var }

  {/if}

  {foreach

*)

//convertion rountines
function DateRecordToStr(Value: TDateRecord): string;         //use FormatSettings
function DateRecordToString(Value: TDateRecord): string;      //FormatSettings independent
function StringToDateRecord(const Value: string): TDateRecord;
function DateTimeFromRecord(Value: TDateRecord): TDateTime;
function DateTimeToRecord(Value: TDateTime): TDateRecord;
function IsEmpty(Value: TDateRecord): boolean;
function GetDateRecordVariant(AYear: word; AMonth: word = 0; ADay: word = 0): Variant;

function GetStartDate(Value: TDateRecord): TDateTime;
function GetEndDate(Value: TDateRecord): TDateTime;

function DoValidIdent(const Value: string): string;

function ParseEscapes(const AStr: string): string;
function SmartyTrim(const S: string): string;
function SmartyTrimLeft(const S: string): string;
function SmartyTrimRight(const S: string): string;
function UCWords(const AStr: string; ACapitalizeDigits: boolean = false): string;
function CountCharacters(const AStr: string; ACountWhitespace: boolean = false): integer;
function TruncateString(const AStr: string; ALength: integer = 80; const AEtc: string = '...';
  ABreakWords: boolean = false; AMiddle: boolean = false): string;
function Strip(const AStr: string; const AStripStr: string = ' '): string;
function StripTags(const AStr: string; ANoSpace: boolean = true;
	AParse: boolean = true): string;
function Spacify(const AStr: string; const ASpacifyStr: string = ' '): string;
function Wordwrap(const Line: string; MaxCol: Integer = 80;
  const BreakStr: string = sLineBreak): string;
function IsLineBreak(C: char): boolean; inline;
function CountParagraphs(const AStr: string): integer;
function CountWords(const AStr: string): integer;
function IndentString(const AStr: string; const IndentStr: string = ' '): string;

function XMLEncode(const AStr: string): string;
function HTMLEncode(const AStr: string): string;
function HTMLEncodeEntities(const AStr: string): string;
function FileEncode(const S: string): string;

//register function or modifier
procedure RegisterModifier(AModifier: TVariableModifierClass);
procedure RegisterFunction(AFunction: TSmartyFunctionClass);
procedure UnregisterFunction(AFunction: TSmartyFunctionClass);

function GetFileContent(const AFilename: string; AEncoding: TEncoding): string;

resourcestring
	sIncorrectArrayItem = 'Invalid key value or array index';
  sIncorrectArrayKey = 'Invalid key value';
  sInvalidParameters = 'Invalid parameters count (%d), required %d-%d in modified %s';
  sInvalidIfCommand = 'Command "%s" found outside of if block';
  sInvalidForEachCommand = 'Command "%s" found outside of foreach block';
  sDuplicateAttribute = 'Duplicate attribute name "%s"';
  sInvalidAttribute = 'Invalid attribute "%s"';
  sInvalidArrayIndex = 'Array index expected by "[" symbol found in variable "%s"';
  sUnpairBrackets = 'Unclose brackets "[" found in variable "%s"';
  sInvalidCharsInArrayIndex = 'Invalid char in variable "%s" array index';
  sInvalidVarChars = 'Invalid char "%s" in variable "%s"';
  sUnclosedBrackets = 'Unclose brackets "[" found in variable "%s"';
  sNamespaceIndexMiss = 'There is no namespace index declaration in variable "%s"';
  sNamespaceVarMiss = 'There is no namespace variable name declaration in variable "%s"';
  sInvalidVariable = 'Invalid variable "%s" declaration';
  sInvalidModifierParams = 'Invalid parameter or modifier name "%s"';
  sInvalidModifier = 'Modifier "%s" do not found';
  sInvalidTemplateChar = 'Unexpected symbol "%s" in template command "%s"';
  sInvalidFunction = 'Function "%s" do not found.';
  sInvalidIntegerConst = 'Invalid integer constant "%s" declaration';
  sInvalidFloatConst = 'Invalid float constant "%s" declaration';
  sInvalidDateConst = 'Invalid date constant "%s" declaration';
  sUncloseFunctionDeclaration = 'Function declaration "%s" is unclosed';
  sFunctionParamsMiss = 'Function "%s" parameters is missed';
  sPathensisDoNotClosed = 'Pathensis ")" do not have corresponding ("(") symbol';
  sClosePathensisExpected = '")" expected but "," found';
  sOpenPathensisExpected  = '"(" expected but ")" or "," found';
  sExpressionExcepted = 'Expression expected but end of expression found';
  sNotOperatorMissied = 'Expression expected after not operator but do not found';
  sOperatorsMissed = 'Expression expected after and before operator but do not found';
  sInvalidExpression = 'Invalid expression';
  sInvalidCharInExpression = 'Unexpected symbol "%s" in expression "%s"';
  sInvalidVarDeclaration = 'Invalid variable declaration "%s" in if block';
  sElseIfAfterElseBlock = 'Elseif block do not allowed after else';
  sElseAfterElseBlock = 'Only one else block allowed';
  sForEachElseAfterBlockEnd = 'Foreachselse block do not allowed after closed foreach block';
  sFromVariableRequireForEach = 'From parameter required in foreach or capturearray block';
  sDuplicateModifierName = 'Duplicate modifier name';
  sDuplicateFunctionName = 'Duplicate function name';
  sDuplicateNamespaceName = 'Duplicate namespace name';
  sInvalidFunctionDeclaration = 'Invalid function "%s" declaration';
  sOpenBraceInTemplate = 'Unexpected "{" symbol';
  sLiteralDoNotFound = 'Unclosed {literal} direclaration found';
  sInvalidTemplateDirective = 'Invalid directive "%s" in template';
  sUncloseQuote = 'Quote ''"'' do not have corresponding (''"'' ) symbol';
	sCloseBraceWithoutTemplate = 'Unexpected "}" symbol';
  sBraceDoNotClose = 'Expected "}" but do not found';
  sAtPosition = ' at line: %d; position: %d';

implementation

var
 SmartyProvider: TSmartyInfoProvider;

{   = packed record
  	Year: word;         //0 means undefine
    Month, Day: byte;     }

function TDateRecord.GetVariant: Variant;
begin
  Result := VarArrayCreate([0, 2], varInteger);
  Result[0] := Year;
  Result[1] := Month;
  Result[2] := Day;
end;

procedure TDateRecord.SetVariant(AValue: Variant);
begin
  if VarIsArray(AValue) then
  begin
    try Year := AValue[0]; except Year := 0; end;
    try Month := AValue[1]; except Month := 0; end;
    try Day := AValue[2]; except Day := 0; end;
  end;
end;

function GetDateRecordVariant(AYear: word; AMonth: word = 0; ADay: word = 0): Variant;
begin
  Result := VarArrayCreate([0, 2], varInteger);
  Result[0] := AYear;
  Result[1] := AMonth;
  Result[2] := ADay;
end;

function TryStringToBool(const AValue: string; var B: boolean): boolean;
begin
  Result := true;
	if (CompareText('true', AValue) = 0) or (CompareText('1', AValue) = 0) then B := true
  else if (CompareText('false', AValue) = 0) or (CompareText('0', AValue) = 0) then B := false
  else Result := false;
end;


procedure RegisterModifier(AModifier: TVariableModifierClass);
begin
	SmartyProvider.AddModifier(AModifier);
end;

procedure RegisterFunction(AFunction: TSmartyFunctionClass);
begin
	SmartyProvider.AddFunction(AFunction);
end;

procedure UnregisterFunction(AFunction: TSmartyFunctionClass);
begin
	SmartyProvider.DeleteFunction(AFunction);
end;


const
	MaxPrecedence = 11;
  OperatorPrecedence: array[TOperator] of byte = (
    6, {opEq}
    6, {opNeq}
    5, {opGt}
    5, {opLt}
   	5, {opGte}
    5, {opLte}
    6, {opSEq}
    3, {opAdd}
    3, {opSub}
    2, {opMply}
    2, {opDivide}
    2, {opMod}
    2, {opDiv}
    4, {opShl}
    4, {opShr}
    1, {opLogicalNot}
    10, {opLogicalAnd}
    11, {opLogicalOr}
    1, {opBitwiseNot}
    7, {opBitwiseAnd}
    9, {opBitwiseOr}
    8  {opBitwiseXor}
  );

function IsSpace(C: char): boolean; inline;
begin
	Result := (C <= ' ') or TCharacter.IsWhiteSpace(C);
end;

function GetChar(const S: string; Index: integer): Char; inline;
begin
  if Index <= Length(S) then
    Result := S[Index]
  else
    Result := #0;
end;

function StartsWithSpace(const ASubStr, AStr: string): boolean;
begin
  Result := StartsStr(ASubStr, AStr) and (Length(AStr) > Length(ASubStr))
  	and IsSpace(AStr[Length(ASubStr) + 1]);
end;

function DateTimeFromString(const ADate: string): TDateTime;
// Convert the string ADate to a TDateTime according to the W3C date/time specification
// as found here: http://www.w3.org/TR/NOTE-datetime
var
  AYear, AMonth, ADay, AHour, AMin, ASec, AMSec: word;
begin
  AYear  := StrToInt(Copy(ADate, 1, 4));
  AMonth := StrToInt(Copy(ADate, 6, 2));
  ADay   := StrToInt(Copy(ADate, 9, 2));
  if Length(ADate) > 16 then
  begin
    AHour := StrToInt(Copy(ADate, 12, 2));
    AMin  := StrToInt(Copy(ADate, 15, 2));
    ASec  := StrToIntDef(Copy(ADate, 18, 2), 0); // They might be omitted, so default to 0
    AMSec := StrToIntDef(Copy(ADate, 21, 3), 0); // They might be omitted, so default to 0
  end
  else begin
    AHour := 0;
    AMin  := 0;
    ASec  := 0;
    AMSec := 0;
  end;
  Result := EncodeDate(AYear, AMonth, ADay) +
  	EncodeTime(AHour, AMin, ASec, AMSec);
end;

function DateLooseFromString(const ADate: string): TDateRecord;
begin
  Result.Year := StrToIntDef(Copy(ADate, 1, 4), 0);
  Result.Month := StrToIntDef(Copy(ADate, 6, 2), 0);
  Result.Day := StrToIntDef(Copy(ADate, 9, 2), 0);
end;

function ParseEscapes(const AStr: string): string;
var
  I, J: integer;
  Ch: Char;
  Hex: integer;

  function IsHexChar(S: string; Index: integer; var HexValue: integer): boolean; inline;
  var
    hCh: Char;
  begin
    if Index <= Length(S) then
    begin
      Result := true;
      hCh := S[Index];

      case hCh of
        '0'..'9': HexValue := HexValue * 16 + Ord(hCh) - Ord('0');
        'a'..'f': HexValue := HexValue * 16 + Ord(hCh) - Ord('a') + 10;
        'A'..'F': HexValue := HexValue * 16 + Ord(hCh) - Ord('A') + 10;
      else
        Result := false;
      end;

    end
    else
      Result := false;
  end;

begin
  Result := '';
  I := 1;

  while I <= Length(AStr) do
  begin
  	Ch := AStr[I];
    Inc(I);

    if (Ch = '\') and (I <= Length(AStr)) then
    begin
      Ch := AStr[I];
      Inc(I);

      if Ch = 'n' then Result := Result + #10
      else if Ch = 'r' then Result := Result + #13
      else if Ch = 't' then Result := Result + #9
      else if Ch = 'a' then Result := Result + #7
      else if Ch = 'b' then Result := Result + #8
      else if Ch = 'v' then Result := Result + #11
      else if Ch = 'e' then Result := Result + #27
      else if Ch = 'f' then Result := Result + #12
      else if Ch = '\' then Result := Result + '\'
      else if Ch = 'x' then
      begin
        Inc(I);
        J := 1;
        Hex := 0;

        while IsHexChar(AStr, I, Hex) and (J <= 6) do
        begin
          Inc(J);
          Inc(I);
        end;

        if Hex <> 0 then
          if Hex >= $10000 then
          begin
            Result := Result + Char(((Hex - $10000) div $400) + $d800) +
              Char(((Hex - $10000) and $3ff) + $dc00);
          end
          else
            Result := Result + Chr((Hex));
      end;
    end
    else
      Result := Result + Ch;
  end;
end;

function IsTrimCharacter(Ch: char): boolean; inline;
begin
  Result := (Ch <= ' ') or TCharacter.IsWhiteSpace(Ch);
end;

function SmartyTrim(const S: string): string;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  if (L > 0) and not IsTrimCharacter(S[I]) and  not IsTrimCharacter(S[L]) then Exit(S);
  while (I <= L) and IsTrimCharacter(S[I]) do Inc(I);
  if I > L then Exit('');
  while IsTrimCharacter(S[L]) do Dec(L);
  Result := Copy(S, I, L - I + 1);
end;

function SmartyTrimLeft(const S: string): string;
var
  I, L: Integer;
begin
  L := Length(S);
  I := 1;
  while (I <= L) and IsTrimCharacter(S[I]) do Inc(I);
  if I = 1 then Exit(S);
  Result := Copy(S, I, Maxint);
end;

function SmartyTrimRight(const S: string): string;
var
  I: Integer;
begin
  I := Length(S);
  if (I > 0) and not IsTrimCharacter(S[I]) then Exit(S);
  while (I > 0) and IsTrimCharacter(S[I]) do Dec(I);
  Result := Copy(S, 1, I);
end;

function IsLetterSymbol(C: char): boolean; inline;
begin
  if (C = '''') or (C = #$2019) then
    Result := true
  else
    case TCharacter.GetUnicodeCategory(C) of
      TUnicodeCategory.ucUppercaseLetter,
      TUnicodeCategory.ucLowercaseLetter,
      TUnicodeCategory.ucTitlecaseLetter,
      TUnicodeCategory.ucModifierLetter,
      TUnicodeCategory.ucOtherLetter,
      TUnicodeCategory.ucNonSpacingMark,
      TUnicodeCategory.ucDashPunctuation:
        Result := true;
    else
      Result := false;
    end;
end;

function UCWords(const AStr: string; ACapitalizeDigits: boolean = false): string;
var
  I, J: integer;
  WasDelimiter, IsNumber: boolean;
  Ch, iCh: char;
  S: string;
begin // FI:C101
  Result := '';
  WasDelimiter := true;
  I := 1;

  while I <= Length(AStr) do
  begin
  	Ch := AStr[I];
    Inc(I);

    if WasDelimiter and TCharacter.IsLetter(Ch) then
    begin
      if ACapitalizeDigits then
      begin
        Result := Result + TCharacter.ToUpper(Ch);
        WasDelimiter := false;
      end
      else begin
        S := '';

        IsNumber := false;
        J := I;
        while J <= Length(AStr) do
        begin
          iCh := AStr[J];
          Inc(J);
          I := J;

          if TCharacter.IsDigit(iCh) then
          begin
            IsNumber := true;
            S := S + iCh;
          end
          else if TCharacter.IsLetter(iCh) or (iCh = '''') or (iCh = #$2019) then
            S := S + iCh
          else begin
            I := J - 1;
            Break;
          end;
        end;

        if IsNumber then
          Result := Result + Ch + S
        else
          Result := Result + TCharacter.ToUpper(Ch) + S;
        WasDelimiter := false;
      end;
    end
    else begin
      Result := Result + Ch;
      WasDelimiter := not (TCharacter.IsDigit(Ch) or TCharacter.IsLetter(Ch) or (Ch = '''') or (Ch = #$2019));
    end;
  end;
end;

function CountCharacters(const AStr: string; ACountWhitespace: boolean = false): integer;
var
  I: integer;
begin
  if ACountWhitespace then
    Result := Length(AStr)
  else begin
    Result := 0;
    for I := 1 to Length(AStr) do
      if not TCharacter.IsWhiteSpace(AStr, I) then Inc(Result);
  end;
end;

function TruncateString(const AStr: string; ALength: integer = 80; const AEtc: string = '...';
  ABreakWords: boolean = false; AMiddle: boolean = false): string;
var
  I, L: integer;
begin
  Result := SmartyTrim(AStr);

  if Length(Result) > ALength then
  begin
    L := ALength div 2;

    if not AMiddle then
    begin
      if ABreakWords then
        Result := Copy(Result, 1, ALength) + AEtc
      else begin
        Result := Copy(Result, 1, ALength + 1);

        I := Length(Result);

        //skip last word up to half of length
        while I > L do
          if IsLetterSymbol(Result[I]) then
            Dec(I)
          else
            Break;

        //skip delimiters up to half of length
        while I > L do
          if not IsLetterSymbol(Result[I]) then
            Dec(I)
          else
            Break;

        Result := Copy(Result, 1, I) + AEtc;
      end;
    end
    else
      Result := Copy(AStr, 1, L) + AEtc + Copy(AStr, Length(AStr) - L + 1, L);
  end;
end;

function Strip(const AStr: string; const AStripStr: string = ' '): string;
var
  I: integer;
  WasWhiteSpace: boolean;
  Ch: char;
begin
  Result := '';
  WasWhiteSpace := false;
  for I := 1 to Length(AStr) do
  begin
    Ch := AStr[I];
    if TCharacter.IsWhiteSpace(Ch) then
      WasWhiteSpace := true
    else begin
      if WasWhiteSpace then
      begin
        WasWhiteSpace := false;
        Result := Result + AStripStr;
      end;

      Result := Result + Ch;
    end;
  end;

  if WasWhiteSpace then Result := Result + AStripStr;
end;

//idea for strip_tags from php sources
function StripTags(const AStr: string; ANoSpace: boolean = true; // FI:C103
	AParse: boolean = true): string;
var
  Br, I, Depth: integer;
  State, Len: integer;
  Ch, LastChar, In_Quote: Char;
  S: string;

  function GetIC(S: string; Index, Len: integer): Char; inline;
  begin
    if (Index > 0) and (Index <= Len) then
      Result := S[Index]
    else
      Result := #0;
  end;

begin // FI:C101
  Result := '';
  S := Strip(AStr);

  I := 0;
  Br := 0;
  Depth := 0;
  In_Quote := #0;
  State := 0;
  LastChar := #0;
  Len := Length(S);

  while I < Len do
  begin
    Inc(I);
    Ch := S[I];

    case Ch of
      '<':
      begin
        if In_Quote <> #0 then
          Continue
        else if State = 0 then
        begin
          LastChar := '<';
          State := 1;

          //check parse tags
          if AParse then
          begin
            if ((GetIC(S, I+1, Len) = '/') and (ToLower(GetIC(S, I+2, Len)) = 'p')) or       //</p
              ((ToLower(GetIC(S, I+1, Len)) = 'b') and (ToLower(GetIC(S, I+2, Len)) = 'r'))  //<br
            then
              Result := Result + #13#10
            else
              if not ANoSpace then Result := Result + ' ';
          end
          else
            if not ANoSpace then Result := Result + ' ';
        end
        else if State = 1 then
        begin
          Inc(Depth);
        end;
      end;

      '(':
      begin
        if State = 2 then
        begin
          if (LastChar <> '"') and (LastChar <> '''') then
          begin
            LastChar := '(';
            Inc(Br);
          end;
        end
        else if State = 0 then
          Result := Result + Ch;
      end;

      ')':
      begin
        if State = 2 then
        begin
          if (LastChar <> '"') and (LastChar <> '''') then
          begin
            LastChar := ')';
            Dec(Br);
          end;

        end
        else if State = 0 then
          Result := Result + Ch;
      end;

      '>':
      begin
        if Depth > 0 then
        begin
          Dec(Depth);
          Continue;
        end;

        if In_Quote <> #0 then
          Continue;

        case State of
          1: // HTML/XML
          begin
            LastChar := '>';
            In_Quote := #0;
            State := 0;
          end;

          2: // PHP
          if (Br = 0) and (LastChar <> '"') and (GetIC(S, I-1, Len) = '?') then
          begin
            In_Quote := #0;
            State := 0;
          end;

          3: //JavaScript/CSS/etc...
          begin
            In_Quote := #0;
            State := 0;
          end;

          4: //Inside <!-- comment -->
          begin
            if (GetIC(S, I-1, Len) = '-') and  (GetIC(S, I-2, Len) = '-') then
            begin
              In_Quote := #0;
              State := 0;
            end;
          end;

        else
          Result := Result + Ch;
        end;

      end;

      '"', '\':
      begin
        if State = 4 then  //Inside <!-- comment -->
          Continue
        else if (State = 2) and (GetIC(S, I-1, Len) = '\') then
        begin
          if LastChar = Ch then
            LastChar := #0
          else if LastChar <> '\' then
            LastChar := Ch;
        end
        else if State = 0 then
          Result := Result + Ch;


        if (State > 0) and (I > 1) and
          ((State = 1) or (GetIC(S, I-1, Len) <> '\')) and
          ((In_Quote = #0) or (Ch = In_Quote)) then
        begin
          if In_Quote <> #0 then
            In_Quote := #0
          else
            In_Quote := Ch;
        end;
      end;

      '!':
      begin
        //JavaScript & Other HTML scripting languages
        if (State = 1) and (GetIC(S, I-1, Len) = '<') then
        begin
          State := 3;
          LastChar := Ch;
        end
        else if State = 0 then
          Result := Result + Ch;
      end;

      '-':
      begin
        if (State = 3) and (GetIC(S, I-1, Len) = '-') and (GetIC(S, I-2, Len) = '!') then
          State := 4
        else if State = 0 then
          Result := Result + Ch;
      end;

      '?':
      begin
        if (State = 1) and (GetIC(S, I-1, Len) = '<') then
        begin
          Br := 0;
          State := 2;
        end
        else if State = 0 then
          Result := Result + Ch;
      end;

      'E', 'e':
      begin
        if (State = 3) and  //!DOCTYPE exception
          (ToLower(GetIC(S, I-1, Len)) = 'p') and
          (ToLower(GetIC(S, I-2, Len)) = 'y') and
          (ToLower(GetIC(S, I-3, Len)) = 't') and
          (ToLower(GetIC(S, I-4, Len)) = 'c') and
          (ToLower(GetIC(S, I-5, Len)) = 'o') and
          (ToLower(GetIC(S, I-6, Len)) = 'd') then
        begin
          State := 1;
        end
        else if State = 0 then
          Result := Result + Ch;
      end;

      'l', 'L':
      begin
        // If we encounter '<?xml' then we shouldn't be in
        // state == 2 (PHP). Switch back to HTML.
        if (State = 2) and
          (ToLower(GetIC(S, I-1, Len)) = 'm') and
          (ToLower(GetIC(S, I-2, Len)) = 'x') then
        begin
          State := 1;
        end
        else if State = 0 then
          Result := Result + Ch;
      end;

    else
      if State = 0 then Result := Result + Ch;
    end;
  end;
end;

function Spacify(const AStr: string; const ASpacifyStr: string = ' '): string;
var
  I, L: integer;
begin
  if Length(AStr) > 0 then
  begin
    Result := '';
    L := Length(AStr);
    for I := 1 to L do
      if I <> L then
        Result := Result + AStr[I] + ASpacifyStr
      else
        Result := Result + AStr[I];
  end
  else
    Result := '';
end;

function Wordwrap(const Line: string; MaxCol: Integer = 80; // FI:C103
  const BreakStr: string = sLineBreak): string;
const
  QuoteChars = ['''', '"'];
var
  Col, Pos: Integer;
  LinePos, LineLen: Integer;
  BreakLen, BreakPos: Integer;
  QuoteChar, CurChar: Char;
  ExistingBreak: Boolean;
  L: Integer;

  function IsBreakChar(Ch: Char): boolean; inline;
  begin
    Result := TCharacter.IsWhiteSpace(Ch) or (Ch = #$0009);
  end;

begin // FI:C101
  Col := 1;
  Pos := 1;
  LinePos := 1;
  BreakPos := 0;
  QuoteChar := #0;
  ExistingBreak := False;
  LineLen := Length(Line);
  BreakLen := Length(BreakStr);
  Result := '';

  while Pos <= LineLen do
  begin
    CurChar := Line[Pos];
    if IsLeadChar(CurChar) then
    begin
      L := CharLength(Line, Pos) div SizeOf(Char) - 1;
      Inc(Pos, L);
      Inc(Col, L);
    end
    else
    begin
      if CharInSet(CurChar, QuoteChars) then
        if QuoteChar = #0 then
          QuoteChar := CurChar
        else if CurChar = QuoteChar then
          QuoteChar := #0;
      if QuoteChar = #0 then
      begin
        if CurChar = BreakStr[1] then
        begin
          ExistingBreak := StrLComp(PChar(BreakStr), PChar(@Line[Pos]), BreakLen) = 0;
          if ExistingBreak then
          begin
            Inc(Pos, BreakLen-1);
            BreakPos := Pos;
          end;
        end;

        if not ExistingBreak then
          if IsBreakChar(CurChar) then
            BreakPos := Pos;
      end;
    end;

    Inc(Pos);
    Inc(Col);

    if not CharInSet(QuoteChar, QuoteChars) and (ExistingBreak or
      ((Col > MaxCol) and (BreakPos > LinePos))) then
    begin
      Col := 1;
      //Result := Result + Copy(Line, LinePos, BreakPos - LinePos + 1);
      Result := Result + Copy(Line, LinePos, BreakPos - LinePos);
      if not CharInSet(CurChar, QuoteChars) then
      begin
        while Pos <= LineLen do
        begin
          if IsBreakChar(Line[Pos]) then
          begin
            Inc(Pos);
            ExistingBreak := False;
          end
          else
          begin
            if StrLComp(PChar(@Line[Pos]), PChar(sLineBreak), Length(sLineBreak)) = 0 then
            begin
              Inc(Pos, Length(sLineBreak));
              ExistingBreak := True;
            end
            else
              Break;
          end;
        end;
      end;
      if (Pos <= LineLen) and not ExistingBreak then
        Result := Result + BreakStr;

      Inc(BreakPos);
      LinePos := BreakPos;
      Pos := LinePos;
      ExistingBreak := False;
    end;
  end;
  Result := Result + Copy(Line, LinePos, MaxInt);
end;

function IsLineBreak(C: char): boolean; inline;
begin
  if Integer(C) <= $FF then
    Result := (C = #$000A) or (C = #$000D) or (C = #$0085)
  else
    case TCharacter.GetUnicodeCategory(C) of
      TUnicodeCategory.ucLineSeparator,
      TUnicodeCategory.ucParagraphSeparator: Result := true
    else
      Result := false;
    end;
end;

function CountParagraphs(const AStr: string): integer;
var
  WasLineBreak: boolean;
  Ch: char;
  I: integer;
begin
  Result := 1;
  WasLineBreak := false;
  for I := 1 to Length(AStr) do
  begin
    Ch := AStr[I];
    if IsLineBreak(Ch) then
      WasLineBreak := true
    else if WasLineBreak then
    begin
      Inc(Result);
      WasLineBreak := false;
    end;
  end;
end;

function CountWords(const AStr: string): integer;
var
  I: integer;
begin
  Result := 0;
  I := 1;
  while I <= Length(AStr) do
  begin
    while (I <= Length(AStr)) and not TCharacter.IsLetter(AStr[I]) do Inc(I);

    if I <= Length(AStr) then
    begin
      Inc(Result);
      while (I <= Length(AStr)) and IsLetterSymbol(AStr[I]) do Inc(I);
    end;
  end;
end;

function IndentString(const AStr: string; const IndentStr: string = ' '): string;
var
  I: integer;
  Ch: char;
  WasLineBreak: boolean;
begin
  Result := '';
  WasLineBreak := false;
  for I := 1 to Length(AStr) do
  begin
    Ch := AStr[I];

    if IsLineBreak(Ch) then
      WasLineBreak := true
    else if WasLineBreak then
    begin
      Result := Result + IndentStr;
      WasLineBreak := false;
    end;

    Result := Result + Ch;
  end;
end;

function XMLEncode(const AStr: string): string;
var
  I: integer;
  Ch: char;
begin
  Result := '';
  for I := 1 to Length(AStr) do
  begin
    Ch := AStr[I];
    case Ch of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '''': Result := Result + '&apos;';
      '"': Result := Result + '&quot;';
    else
      Result := Result + Ch;
    end;
  end;
end;

function HTMLEncode(const AStr: string): string;
var
  I: integer;
  Ch: char;
begin
  Result := '';
  for I := 1 to Length(AStr) do
  begin
    Ch := AStr[I];
    case Ch of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '''': Result := Result + '&#39;';
      '"': Result := Result + '&quot;';
      #160: Result := Result + '&nbsp;';
    else
      Result := Result + Ch;
    end;
  end;
end;

function HTMLEncodeEntities(const AStr: string): string;
var
  I: integer;
  Ch: char;
begin // FI:C101
  Result := '';
  for I := 1 to Length(AStr) do
  begin
    Ch := AStr[I];
    case Ch of
      '&': Result := Result + '&amp;';
      '<': Result := Result + '&lt;';
      '>': Result := Result + '&gt;';
      '''': Result := Result + '&#39;';
      '"': Result := Result + '&quot;';
      #160: Result := Result + '&nbsp;';
      #161: Result := Result + '&iexcl';
      #162: Result := Result + '&cent;';
      #163: Result := Result + '&pound;';
      #164: Result := Result + '&curren;';
      #165: Result := Result + '&yen;';
      #166: Result := Result + '&brvbar;';
      #167: Result := Result + '&sect;';
      #168: Result := Result + '&uml;';
      #169: Result := Result + '&copy;';
      #170: Result := Result + '&ordf;';
      #171: Result := Result + '&laquo;';
      #172: Result := Result + '&not;';
      #173: Result := Result + '&shy;';
      #174: Result := Result + '&reg;';
      #175: Result := Result + '&macr;';
      #176: Result := Result + '&deg;';
      #177: Result := Result + '&plusmn;';
      #178: Result := Result + '&sup2;';
      #179: Result := Result + '&sup3;';
      #180: Result := Result + '&acute;';
      #181: Result := Result + '&micro;';
      #182: Result := Result + '&para;';
      #183: Result := Result + '&middot;';
      #184: Result := Result + '&cedil;';
      #185: Result := Result + '&sup1;';
      #186: Result := Result + '&ordm;';
      #187: Result := Result + '&raquo;';
      #188: Result := Result + '&frac14;';
      #189: Result := Result + '&frac12;';
      #190: Result := Result + '&frac34;';
      #191: Result := Result + '&iquest;';
      #192: Result := Result + '&Agrave;';
      #193: Result := Result + '&Aacute;';
      #194: Result := Result + '&Acirc;';
      #195: Result := Result + '&Atilde;';
      #196: Result := Result + '&Auml;';
      #197: Result := Result + '&Aring;';
      #198: Result := Result + '&AElig;';
      #199: Result := Result + '&Ccedil;';
      #200: Result := Result + '&Egrave;';
      #201: Result := Result + '&Eacute;';
      #202: Result := Result + '&Ecirc;';
      #203: Result := Result + '&Euml;';
      #204: Result := Result + '&Igrave;';
      #205: Result := Result + '&Iacute;';
      #206: Result := Result + '&Icirc;';
      #207: Result := Result + '&Iuml;';
      #208: Result := Result + '&ETH;';
      #209: Result := Result + '&Ntilde;';
      #210: Result := Result + '&Ograve;';
      #211: Result := Result + '&Oacute;';
      #212: Result := Result + '&Ocirc;';
      #213: Result := Result + '&Otilde;';
      #214: Result := Result + '&Ouml;';
      #215: Result := Result + '&times;';
      #216: Result := Result + '&Oslash;';
      #217: Result := Result + '&Ugrave;';
      #218: Result := Result + '&Uacute;';
      #219: Result := Result + '&Ucirc;';
      #220: Result := Result + '&Uuml;';
      #221: Result := Result + '&Yacute;';
      #222: Result := Result + '&THORN;';
      #223: Result := Result + '&szlig;';
      #224: Result := Result + '&agrave;';
      #225: Result := Result + '&aacute;';
      #226: Result := Result + '&acirc;';
      #227: Result := Result + '&atilde;';
      #228: Result := Result + '&auml;';
      #229: Result := Result + '&aring;';
      #230: Result := Result + '&aelig;';
      #231: Result := Result + '&ccedil;';
      #232: Result := Result + '&egrave;';
      #233: Result := Result + '&eacute;';
      #234: Result := Result + '&ecirc;';
      #235: Result := Result + '&euml;';
      #236: Result := Result + '&igrave;';
      #237: Result := Result + '&iacute;';
      #238: Result := Result + '&icirc;';
      #239: Result := Result + '&iuml;';
      #240: Result := Result + '&eth;';
      #241: Result := Result + '&ntilde;';
      #242: Result := Result + '&ograve;';
      #243: Result := Result + '&oacute;';
      #244: Result := Result + '&ocirc;';
      #245: Result := Result + '&otilde;';
      #246: Result := Result + '&ouml;';
      #247: Result := Result + '&divide;';
      #248: Result := Result + '&oslash;';
      #249: Result := Result + '&ugrave;';
      #250: Result := Result + '&uacute;';
      #251: Result := Result + '&ucirc;';
      #252: Result := Result + '&uuml;';
      #253: Result := Result + '&yacute;';
      #254: Result := Result + '&thorn;';
      #255: Result := Result + '&yuml;';
      #338: Result := Result + '&OElig;';
      #339: Result := Result + '&oelig;';
      #352: Result := Result + '&Scaron;';
      #353: Result := Result + '&scaron;';
      #376: Result := Result + '&Yuml;';
      #402: Result := Result + '&fnof;';
      #710: Result := Result + '&circ;';
      #732: Result := Result + '&tilde;';
      #913: Result := Result + '&Alpha;';
      #914: Result := Result + '&Beta;';
      #915: Result := Result + '&Gamma;';
      #916: Result := Result + '&Delta;';
      #917: Result := Result + '&Epsilon;';
      #918: Result := Result + '&Zeta;';
      #919: Result := Result + '&Eta;';
      #920: Result := Result + '&Theta;';
      #921: Result := Result + '&Iota;';
      #922: Result := Result + '&Kappa;';
      #923: Result := Result + '&Lambda;';
      #924: Result := Result + '&Mu;';
      #925: Result := Result + '&Nu;';
      #926: Result := Result + '&Xi;';
      #927: Result := Result + '&Omicron;';
      #928: Result := Result + '&Pi;';
      #929: Result := Result + '&Rho;';
      #931: Result := Result + '&Sigma;';
      #932: Result := Result + '&Tau;';
      #933: Result := Result + '&Upsilon;';
      #934: Result := Result + '&Phi;';
      #935: Result := Result + '&Chi;';
      #936: Result := Result + '&Psi;';
      #937: Result := Result + '&Omega;';
      #945: Result := Result + '&alpha;';
      #946: Result := Result + '&beta;';
      #947: Result := Result + '&gamma;';
      #948: Result := Result + '&delta;';
      #949: Result := Result + '&epsilon;';
      #950: Result := Result + '&zeta;';
      #951: Result := Result + '&eta;';
      #952: Result := Result + '&theta;';
      #953: Result := Result + '&iota;';
      #954: Result := Result + '&kappa;';
      #955: Result := Result + '&lambda;';
      #956: Result := Result + '&mu;';
      #957: Result := Result + '&nu;';
      #958: Result := Result + '&xi;';
      #959: Result := Result + '&omicron;';
      #960: Result := Result + '&pi;';
      #961: Result := Result + '&rho;';
      #962: Result := Result + '&sigmaf;';
      #963: Result := Result + '&sigma;';
      #964: Result := Result + '&tau;';
      #965: Result := Result + '&upsilon;';
      #966: Result := Result + '&phi;';
      #967: Result := Result + '&chi;';
      #968: Result := Result + '&psi;';
      #969: Result := Result + '&omega;';
      #977: Result := Result + '&thetasym;';
      #978: Result := Result + '&upsih;';
      #982: Result := Result + '&piv;';
      #8194: Result := Result + '&ensp;';
      #8195: Result := Result + '&emsp;';
      #8201: Result := Result + '&thinsp;';
      #8204: Result := Result + '&zwnj;';
      #8205: Result := Result + '&zwj;';
      #8206: Result := Result + '&lrm;';
      #8207: Result := Result + '&rlm;';
      #8211: Result := Result + '&ndash;';
      #8212: Result := Result + '&mdash;';
      #8216: Result := Result + '&lsquo;';
      #8217: Result := Result + '&rsquo;';
      #8218: Result := Result + '&sbquo;';
      #8220: Result := Result + '&ldquo;';
      #8221: Result := Result + '&rdquo;';
      #8222: Result := Result + '&bdquo;';
      #8224: Result := Result + '&dagger;';
      #8225: Result := Result + '&Dagger;';
      #8226: Result := Result + '&bull;';
      #8230: Result := Result + '&hellip;';
      #8240: Result := Result + '&permil;';
      #8242: Result := Result + '&prime;';
      #8243: Result := Result + '&Prime;';
      #8249: Result := Result + '&lsaquo;';
      #8254: Result := Result + '&oline;';
      #8250: Result := Result + '&rsaquo;';
      #8260: Result := Result + '&frasl;';
      #8364: Result := Result + '&euro;';
      #8472: Result := Result + '&weierp;';
      #8465: Result := Result + '&image;';
      #8476: Result := Result + '&real;';
      #8482: Result := Result + '&trade;';
      #8501: Result := Result + '&alefsym;';
      #8592: Result := Result + '&larr;';
      #8593: Result := Result + '&uarr;';
      #8594: Result := Result + '&rarr;';
      #8595: Result := Result + '&darr;';
      #8596: Result := Result + '&harr;';
      #8629: Result := Result + '&crarr;';
      #8656: Result := Result + '&lArr;';
      #8657: Result := Result + '&uArr;';
      #8658: Result := Result + '&rArr;';
      #8659: Result := Result + '&dArr;';
      #8660: Result := Result + '&hArr;';
      #8704: Result := Result + '&forall;';
      #8706: Result := Result + '&part;';
      #8707: Result := Result + '&exist;';
      #8709: Result := Result + '&empty;';
      #8711: Result := Result + '&nabla;';
      #8712: Result := Result + '&isin;';
      #8713: Result := Result + '&notin;';
      #8715: Result := Result + '&ni;';
      #8719: Result := Result + '&prod;';
      #8721: Result := Result + '&sum;';
      #8722: Result := Result + '&minus;';
      #8727: Result := Result + '&lowast;';
      #8730: Result := Result + '&radic;';
      #8733: Result := Result + '&prop;';
      #8734: Result := Result + '&infin;';
      #8736: Result := Result + '&ang;';
      #8743: Result := Result + '&and;';
      #8744: Result := Result + '&or;';
      #8745: Result := Result + '&cap;';
      #8746: Result := Result + '&cup;';
      #8747: Result := Result + '&int;';
      #8756: Result := Result + '&there4;';
      #8764: Result := Result + '&sim;';
      #8773: Result := Result + '&cong;';
      #8776: Result := Result + '&asymp;';
      #8800: Result := Result + '&ne;';
      #8801: Result := Result + '&equiv;';
      #8804: Result := Result + '&le;';
      #8805: Result := Result + '&ge;';
      #8834: Result := Result + '&sub;';
      #8835: Result := Result + '&sup;';
      #8836: Result := Result + '&nsub;';
      #8838: Result := Result + '&sube;';
      #8839: Result := Result + '&supe;';
      #8853: Result := Result + '&oplus;';
      #8855: Result := Result + '&otimes;';
      #8869: Result := Result + '&perp;';
      #8901: Result := Result + '&sdot;';
      #8968: Result := Result + '&lceil;';
      #8969: Result := Result + '&rceil;';
      #8970: Result := Result + '&lfloor;';
      #8971: Result := Result + '&rfloor;';
      #9001: Result := Result + '&lang;';
      #9002: Result := Result + '&rang;';
      #9674: Result := Result + '&loz;';
      #9824: Result := Result + '&spades;';
      #9827: Result := Result + '&clubs;';
      #9829: Result := Result + '&hearts;';
      #9830: Result := Result + '&diams;';
    else
      Result := Result + Ch;
    end;
  end;
end;

function FileEncode(const S: string): string;
var
	I: Integer;
begin
  Result := 'file:///';
  for I := 1 to Length(S) do
  begin
  	if S[I] = '\' then
    	Result := Result + '/'
    else if CharInSet(S[I], ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '/', ':']) then
      Result := Result + S[I]
    else
      Result := Result + '%' + IntToHex(Ord(S[I]), 2);
  end;
end;

{************* TVariableRecord *************}

procedure TVariableRecord.Finalize;
var
	ArrayData: PVariableArray;
  I: integer;
begin
	case Self.VarType of
    vtString:
    begin
    	string(Self.SValue) := '';
      Self.SValue := nil;
    end;
    vtArray:
    begin
    	ArrayData := Self.AValue;
      if ArrayData.Count > 0 then
      begin
        for I := 0 to ArrayData.Count - 1 do
        begin
          string(ArrayData.Data[I].Key) := '';
          ArrayData.Data[I].Item.Finalize;
        end;
      	FreeMem(ArrayData.Data, ArrayData.Count * SizeOf(TVariableArrayItem));
      end;
      FreeMem(Self.AValue, SizeOf(TVariableArray));
    end;
  end;
end;

function TVariableRecord.Clone: TVariableRecord;
var
	ArrayData: PVariableArray;
  I: integer;
begin
  Result.VarType := Self.VarType;
  case Self.VarType of
    vtNull: ;
    vtBoolean:
    	Result.BValue := Self.BValue;
    vtInteger:
    	Result.IValue := Self.IValue;
    vtFloat:
    	Result.FValue := Self.FValue;
    vtDateStrict:
    	Result.DSValue := Self.DSValue;
    vtDateLoose:
    	Result.DLValue := Self.DLValue;
    vtDateTime:
    	Result.DTValue := Self.DTValue;
    vtString:
    begin
    	Result.SValue := nil;
    	string(Result.SValue) := string(Self.SValue);
    end;
    vtArray:
    begin
      Result.AValue := AllocMem(SizeOf(TVariableArray));
      ArrayData := Result.AValue;
      PVariableArray(Result.AValue).Count := PVariableArray(Self.AValue).Count;
      PVariableArray(Result.AValue).Reference := PVariableArray(Self.AValue).Reference;
      if PVariableArray(Self.AValue).Count > 0 then
      begin
        ArrayData.Data := AllocMem(ArrayData.Count * SizeOf(TVariableArrayItem));
        for I := 0 to ArrayData.Count - 1 do
        begin
        	ArrayData.Data[I].Key := nil;
          string(ArrayData.Data[I].Key) := string(PVariableArray(Self.AValue).Data[I].Key);
          ArrayData.Data[I].Item := PVariableArray(Self.AValue).Data[I].Item.Clone;
        end;
      end
      else
      	ArrayData.Data := nil;
    end;
  end;
end;

function TVariableRecord.IsNull: boolean;
begin
	Result := (Self.VarType = vtNull);
end;

function TVariableRecord.IsEmpty: boolean;
begin
  case Self.VarType of
    vtNull:
    	Result := true;
    vtBoolean:
    	Result := false;
    vtInteger:
    	Result := (Self.IValue = 0);
    vtFloat:
    	Result := (Self.FValue = 0);
    vtDateStrict:
    	Result := (Self.DSValue = 0);
    vtDateLoose:
    	Result := (Self.DLValue.Year = 0) and	(Self.DLValue.Month = 0) and (Self.DLValue.Day = 0);
    vtDateTime:
    	Result := (Self.DTValue = 0);
    vtString:
    	Result := (string(Self.SValue) = '');
    vtArray:
    	Result := (PVariableArray(Self.AValue).Count = 0);
  else
  	Result := true;
  end;
end;

function TVariableRecord.IsArray: boolean;
begin
	Result := (Self.VarType = vtArray);
end;

function TVariableRecord.IsBoolean: boolean;
begin
	Result := (Self.VarType = vtBoolean);
end;

function TVariableRecord.IsInteger: boolean;
begin
	Result := (Self.VarType = vtInteger);
end;

function TVariableRecord.IsFloat: boolean;
begin
	Result := (Self.VarType = vtFloat);
end;

function TVariableRecord.IsNumber: boolean;
begin
	Result := (Self.VarType = vtInteger) or (Self.VarType = vtFloat);
end;

function TVariableRecord.IsDateStrict: boolean;
begin
	Result := (Self.VarType = vtDateStrict);
end;

function TVariableRecord.IsDateLoose: boolean;
begin
	Result := (Self.VarType = vtDateLoose);
end;

function TVariableRecord.IsDateTime: boolean;
begin
	Result := (Self.VarType = vtDateTime);
end;

function TVariableRecord.IsDate: boolean;
begin
	Result := (Self.VarType = vtDateStrict) or (Self.VarType = vtDateLoose) or
    (Self.VarType = vtDateTime);
end;

function TVariableRecord.IsString: boolean;
begin
	Result := (Self.VarType = vtString);
end;

class function TVariableRecord.Null: TVariableRecord;
begin
	Result.VarType := vtNull;
end;

class function TVariableRecord.AsInteger(AValue: integer;
	ANullValue: integer = 0): TVariableRecord;
begin
	if AValue <> ANullValue then
  	Result := AValue
  else
  	Result.VarType := vtNull;
end;

class function TVariableRecord.AsFloat(AValue: double; ANullValue: double = 0): TVariableRecord;
begin
	if AValue <> ANullValue then
  	Result := AValue
  else
  	Result.VarType := vtNull;
end;

class function TVariableRecord.AsString(AValue: string; ANullValue: string = ''): TVariableRecord;
begin
	if AValue <> ANullValue then
  	Result := AValue
  else
  	Result.VarType := vtNull;
end;

class function TVariableRecord.AsDateRecord(AValue: TDateRecord): TVariableRecord;
begin
	if (AValue.Year <> 0) or (AValue.Month <> 0) or (AValue.Day <> 0) then
  	Result := AValue
  else
  	Result.VarType := vtNull;
end;

procedure TVariableRecord.SetNull;
begin
	Finalize;
  VarType := vtNull;
end;

procedure TVariableRecord.SetBool(AValue: boolean);
begin
	Finalize;
  VarType := vtBoolean;
  BValue := AValue;
end;

procedure TVariableRecord.SetInt(AValue: integer);
begin
	Finalize;
	VarType := vtInteger;
  IValue := AValue;
end;

procedure TVariableRecord.SetFloat(Avalue: double);
begin
	Finalize;
	VarType := vtFloat;
  FValue := AValue;
end;

procedure TVariableRecord.SetString(AValue: string);
begin
	Finalize;
	VarType := vtString;
  SValue := nil;
  string(SValue) := AValue;
end;

procedure TVariableRecord.SetArrayLength(AValue: integer;
	AReference: TObject = nil; AInit: boolean = false);
var
	ArrayData: PVariableArray;
  I: integer;
begin
  VarType := vtArray;
  Self.AValue := AllocMem(SizeOf(TVariableArray));
  ArrayData := Self.AValue;
  ArrayData.Data := AllocMem(AValue * SizeOf(TVariableArrayItem));
  ArrayData.Count := AValue;
  ArrayData.Reference := AReference;

  if AInit then
    for I := 0 to AValue - 1 do
    begin
      ArrayData.Data[I].Key := nil;
      ArrayData.Data[I].Item := TVariableRecord.Null;
    end;
end;

procedure TVariableRecord.SetArrayItem(AIndex: integer;
	AKey: string; AValue: TVariableRecord);
var
	ArrayData: PVariableArray;
begin
  ArrayData := Self.AValue;
  if (AIndex >= 0) and (AIndex < ArrayData.Count) then
  begin
    ArrayData.Data[AIndex].Key := nil;
 		string(ArrayData.Data[AIndex].Key) := DoValidIdent(AKey);
  	ArrayData.Data[AIndex].Item := AValue;
  end
  else
  	raise ESmartyException.CreateRes(@sIncorrectArrayItem);
end;

procedure TVariableRecord.SetArrayItemQ(AIndex: integer;
	AKey: string; AValue: TVariableRecord);
var
	ArrayData: PVariableArray;
begin
  ArrayData := Self.AValue;
  Assert((AIndex >= 0) and (AIndex < ArrayData.Count), 'Invalid array item');
  if (AKey = '') or IsValidIdent(AKey) then
  begin  
    ArrayData.Data[AIndex].Key := nil;
  	string(ArrayData.Data[AIndex].Key) := AKey;
  	ArrayData.Data[AIndex].Item := AValue;
  end
  else
  	raise ESmartyException.CreateRes(@sIncorrectArrayKey);
end;

class operator TVariableRecord.Implicit(AValue: boolean): TVariableRecord;
begin
  Result.VarType := vtBoolean;
  Result.BValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: integer): TVariableRecord;
begin
	Result.VarType := vtInteger;
  Result.IValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: double): TVariableRecord;
begin
	Result.VarType := vtFloat;
  Result.FValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: extended): TVariableRecord;
begin
	Result.VarType := vtFloat;
  Result.FValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: TDate): TVariableRecord;
begin
	Result.VarType := vtDateStrict;
  Result.DSValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: TDateRecord): TVariableRecord;
begin
	Result.VarType := vtDateLoose;
  Result.DLValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: TDateTime): TVariableRecord;
begin
	Result.VarType := vtDateTime;
  Result.DTValue := AValue;
end;

class operator TVariableRecord.Implicit(AValue: string): TVariableRecord;
begin
	Result.VarType := vtString;
  Result.SValue := nil;
  string(Result.SValue) := AValue;
end;

class operator TVariableRecord.Implicit(ARecord: TVariableRecord): boolean;
begin
	Result := ARecord.ToBool;
end;

class operator TVariableRecord.Implicit(ARecord: TVariableRecord): integer;
begin
	Result := ARecord.ToInt;
end;

class operator TVariableRecord.Implicit(ARecord: TVariableRecord): double;
begin
	Result := ARecord.ToFloat;
end;

class operator TVariableRecord.Implicit(ARecord: TVariableRecord): string;
begin
	Result := ARecord.ToString;
end;

function TVariableRecord.ToBool: boolean;
var
	I: integer;
	ArrayData: PVariableArray;
begin
  case Self.VarType of
    vtNull:
    	Result := false;
    vtBoolean:
    	Result := Self.BValue;
    vtInteger:
    	Result := (Self.IValue <> 0);
    vtFloat:
    	Result := (Self.FValue <> 0);
    vtDateStrict:
    	Result := (Self.DSValue <> 0);
    vtDateLoose:
    	Result := (Self.DLValue.Year <> 0) or (Self.DLValue.Month <> 0) or
    	(Self.DLValue.Day <> 0);
    vtDateTime:
    	Result := (Self.DTValue <> 0);
    vtString:
  	begin
    	Result := (string(Self.SValue) <> '') and (string(Self.SValue) <> '0') and 
      	not AnsiSameText(string(Self.SValue), DefaultFalseBoolStr);
    end;
    vtArray:
    begin
      ArrayData := Self.AValue;
    	Result := ArrayData.Count > 0;
      if Result then
      begin
      	Result := false;
      	for I := 0 to ArrayData.Count - 1 do
      	begin
        	Result := Result or ArrayData.Data[I].Item.ToBool;
          if Result then Break;
      	end;
      end;
    end
  else
  	Result := false;
  end;
end;

function TVariableRecord.ToInt: integer;
begin
	case Self.VarType of
    vtNull:
    	Result := 0;
    vtBoolean:
    	if Self.BValue then Result := 1 else Result := 0;
    vtInteger:
    	Result := Self.IValue;
    vtFloat:
    	Result := Round(Self.FValue);
    vtDateStrict:
    	Result := Round(Self.DSValue);
    vtDateLoose:
    	Result := Round(DateTimeFromRecord(Self.DLValue));
    vtDateTime:
    	Result := Round(Self.DTValue);
    vtString:
    	Result := StrToIntDef(string(Self.SValue), 0);
    vtArray:
    	if ToBool then Result := 1 else Result := 0;
  else
  	Result := 0;
  end;
end;

function TVariableRecord.ToFloat: double;
begin
	case Self.VarType of
    vtNull:
    	Result := 0;
    vtBoolean:
    	if Self.BValue then Result := 1 else Result := 0;
    vtInteger:
    	Result := Self.IValue;
    vtFloat:
    	Result := Self.FValue;
    vtDateStrict:
    	Result := Self.DSValue;
    vtDateLoose:
    	Result := DateTimeFromRecord(Self.DLValue);
    vtDateTime:
    	Result := Self.DTValue;
    vtString:
    	Result := StrToFloatDef(string(Self.SValue), 0);
    vtArray:
    	if ToBool then Result := 1 else Result := 0;
  else
  	Result := 0;
  end;
end;

function TVariableRecord.ToString: string;
begin
	case Self.VarType of
    vtNull:
    	Result := '';
    vtBoolean:
    	if Self.BValue then Result := '1' else Result := '';
    vtInteger:
    	Result := IntToStr(Self.IValue);
    vtFloat:
    	Result := FloatToStr(Self.FValue);
    vtDateStrict:
    	Result := DateToStr(Self.DSValue);
    vtDateLoose:
    	Result := DateRecordToStr(Self.DLValue);
    vtDateTime:
    	Result := DateTimeToStr(Self.DTValue);
    vtString:
    	Result := string(Self.SValue);
    vtArray:
    	Result := 'Array';
  end;
end;

function TVariableRecord.CanConvertToLogical(out Value: boolean): boolean;
begin
	case Self.VarType of
    vtNull:
    	Result := false;
    vtBoolean:
    begin
    	Value := Self.BValue;
      Result := true;
    end;
    vtInteger, vtFloat, vtDateStrict, vtDateLoose, vtDateTime, vtArray:
    	Result := false;
    vtString:
    	Result := TryStrToBool(string(Self.SValue), Value);
  else
  	Result := false;
  end;
end;

function TVariableRecord.CanConvertToInt(out Value: integer): boolean;
begin
	case Self.VarType of
    vtNull:
    	Result := false;
    vtBoolean:
    begin
    	if Self.BValue then Value := 1 else Value := 0;
      Result := true;
    end;
    vtInteger:
    begin
    	Value := Self.IValue;
    	Result := true;
    end;
    vtDateStrict:
    begin
    	Value := Round(Self.DSValue);
    	Result := true;
    end;
    vtFloat, vtDateLoose, vtDateTime, vtArray:
    	Result := false;
    vtString:
    	Result := TryStrToInt(string(Self.SValue), Value);
  else
  	Result := false;
  end;
end;

function TVariableRecord.CanConvertToFloat(out Value: double): boolean;
begin
	case Self.VarType of
    vtNull, vtArray:
    	Result := false;
    vtBoolean:
    begin
    	if Self.BValue then Value := 1 else Value := 0;
      Result := true;
    end;
    vtInteger:
    begin
    	Value := Self.IValue;
    	Result := true;
    end;
    vtFloat:
    begin
    	Value := Self.FValue;
    	Result := true;
    end;
    vtDateStrict:
    begin
    	Value := Self.DSValue;
    	Result := true;
    end;
    vtDateLoose:
    begin
    	Value := DateTimeFromRecord(Self.DLValue);
      Result := true;
    end;
    vtDateTime:
    begin
    	Value := Self.DTValue;
    	Result := true;
    end;
    vtString:
    	Result := TryStrToFloat(string(Self.SValue), Value);
  else
  	Result := false;
  end;
end;

class function TVariableRecord.DoCompareRelationship(ALeft, ARight: TVariableRecord; // FI:C103
	AOperation: TCompareOperation): TVariableRelatioship;
var
	CompareType: TVariableType;
  B1, B2: boolean;
  I, I1, I2, SCompare: integer;
  F1, F2, DCompare: double;
  S1, S2: string;
  DL: TDateRecord;
  StartTime, EndTime: TDateTime;
  VA1, VA2: PVariableArray;
const
  CBaseTypes: array [TVariableType, TVariableType] of TVariableType =
           {Null}     {Bool}     {Int}       {Float}      {Date}      {DateLoose}   {DateTime}    {String}      {Array}
{Null} ((vtNull,    vtBoolean, vtBoolean,   vtBoolean,   vtBoolean,    vtBoolean,   vtBoolean,   vtBoolean,    vtBoolean),
{Bool}  (vtBoolean, vtBoolean, vtBoolean,   vtBoolean,   vtBoolean,    vtBoolean,   vtBoolean,   vtBoolean,    vtBoolean),
{Int}   (vtBoolean, vtBoolean, vtInteger,   vtFloat,     vtInteger,    vtDateLoose, vtFloat,     vtFloat,      vtInteger),
{Float} (vtBoolean, vtBoolean, vtFloat,     vtFloat,     vtFloat,      vtDateLoose, vtFloat,     vtFloat,      vtFloat),
{Date}  (vtBoolean, vtBoolean, vtInteger,   vtFloat,     vtDateStrict, vtDateLoose, vtDateTime,  vtDateStrict, vtDateStrict),
{DateL} (vtBoolean, vtBoolean, vtDateLoose, vtDateLoose, vtDateLoose,  vtDateLoose, vtDateLoose, vtDateLoose,  vtDateLoose),
{DateT} (vtBoolean, vtBoolean, vtFloat,     vtFloat,     vtDateTime,   vtDateLoose, vtDateTime,  vtDateTime,   vtDateTime),
{Str}   (vtBoolean, vtBoolean, vtFloat,     vtFloat,     vtDateStrict, vtDateLoose, vtDateTime,  vtString,     vtString),
{Array} (vtBoolean, vtBoolean, vtInteger,   vtFloat,     vtDateStrict, vtDateLoose, vtDateTime,  vtString,     vtArray));
begin // FI:C101
	if AOperation <> coSEq then
  begin
  	CompareType := CBaseTypes[ALeft.VarType, ARight.VarType];
   	case CompareType of
      vtNull:
      	Result := vrEqual;

      vtBoolean:
      begin
      	B1 := ALeft.ToBool;
        B2 := ARight.ToBool;
        if B1 > B2 then Result := vrGreaterThan
        else if B1 = B2 then Result := vrEqual
        else Result := vrLessThan;
      end;

      vtDateStrict, vtInteger:
      begin
      	I1 := ALeft.ToInt;
        I2 := ARight.ToInt;
        if I1 > I2 then Result := vrGreaterThan
        else if I1 = I2 then Result := vrEqual
        else Result := vrLessThan;
      end;

      vtFloat, vtDateTime:
      begin
      	F1 := ALeft.ToFloat;
        F2 := ARight.ToFloat;
        if F1 > F2 then Result := vrGreaterThan
        else if F1 = F2 then Result := vrEqual
        else Result := vrLessThan;
      end;

      vtDateLoose:
      begin
      	if ALeft.VarType = vtDateLoose then
        begin
          DL := ALeft.DLValue;
          DCompare := ARight.ToFloat;
          StartTime := GetStartDate(DL);
          EndTime := GetEndDate(DL);
          if StartTime > DCompare then
          	Result := vrGreaterThan
          else if EndTime < DCompare then
          	Result := vrLessThan
          else
          	Result := vrEqual;
        end
        else begin
          DL := ARight.DLValue;
          DCompare := ALeft.ToFloat;
          StartTime := GetStartDate(DL);
          EndTime := GetEndDate(DL);
          if DCompare < StartTime then
          	Result := vrLessThan
          else if DCompare > EndTime then
          	Result := vrGreaterThan
          else
          	Result := vrEqual;
        end;
      end;

      vtString:
      begin
      	S1 := ALeft.ToString;
        S2 := ARight.ToString;
        SCompare := CompareStr(S1, S2);
        if SCompare > 0 then Result := vrGreaterThan
        else if SCompare = 0 then Result := vrEqual
        else Result := vrLessThan;
      end;

      vtArray: 
      begin
      	I1 := PVariableArray(ALeft.AValue).Count;
      	I2 := PVariableArray(ALeft.AValue).Count;
        if I1 > I2 then Result := vrGreaterThan
        else if I1 = I2 then Result := vrEqual
        else Result := vrLessThan;
      end;
    else
    	Result := vrEqual;
    end;

  end
  else begin
  	//SEq operation
    if ALeft.VarType <> ARight.VarType then
    	Result := vrGreaterThan
    else begin
    	case ALeft.VarType of
        vtNull:
        	Result := vrEqual;

        vtBoolean:
        	if ALeft.BValue = ARight.BValue then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;

        vtInteger:
        	if ALeft.IValue = ARight.IValue then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;

        vtFloat:
        	if ALeft.FValue = ARight.FValue then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;

        vtDateStrict:
        	if ALeft.DSValue = ARight.DSValue then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;

        vtDateLoose:
        begin
        	if (ALeft.DLValue.Year = ARight.DLValue.Year) and
             (ALeft.DLValue.Month = ARight.DLValue.Month) and
             (ALeft.DLValue.Day = ARight.DLValue.Day) then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;
        end;

        vtDateTime:
        	if ALeft.DTValue = ARight.DTValue then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;

        vtString:
        	if string(ALeft.SValue) = string(ARight.SValue) then
          	Result := vrEqual
          else
          	Result := vrGreaterThan;

        vtArray: 
        begin
      		VA1 := PVariableArray(ALeft.AValue);
      		VA2 := PVariableArray(ALeft.AValue);
          if VA1.Count = VA2.Count then
          begin
          	Result := vrEqual;

          	if VA1.Count > 0 then            
              for I := 0 to VA1.Count - 1 do
              begin
                Result := DoCompareRelationship(VA1.Data[I].Item, VA2.Data[I].Item, AOperation);
                if Result <> vrEqual then Break;               
              end
          end
          else
          	Result := vrGreaterThan;
        end;
      else
    		Result := vrEqual;
      end;
    end;
  end;
end;

class function TVariableRecord.DoCompare(ALeft, ARight: TVariableRecord;
	AOperation: TCompareOperation): boolean;
const
  CRelationshipToBoolean: array [TCompareOperation, TVariableRelatioship] of boolean =
  //  vrGreaterThan, vrEqual, vrLessThan
    ((False, True,  False),  // coEq
     (True,  False, True),   // coNeq
     (True,  False, False),  // coGt
     (False, False, True),   // coLt
     (True,  True,  False),  // coGte
     (False, True,  True),   // coLte
     (False, True,  False)); // coSEq
var
	Realationship: TVariableRelatioship;
begin
	Realationship := DoCompareRelationship(ALeft, ARight, AOperation);
  Result := CRelationshipToBoolean[AOperation, Realationship];
end;

class function TVariableRecord.DoIntFloatOp(ALeft, ARight: TVariableRecord; // FI:C103
	AOperation: TBinaryOperation): TVariableRecord;
var
	I1, I2: integer;
  F1, F2: double;
  CanI1, CanI2, CanF1, CanF2: boolean;
begin // FI:C101
  CanI1 := ALeft.CanConvertToInt(I1);
  CanI2 := ARight.CanConvertToInt(I2);
  if CanI1 and CanI2 then
  begin
    case AOperation of
      voAdd:
      	Result := I1 + I2;
      voSubtract:
      	Result := I1 - I2;
      voMultiply:
      	Result := I1 * I2;
    end;
  end
  else begin
    CanF1 := ALeft.CanConvertToFloat(F1);
    CanF2 := ARight.CanConvertToFloat(F2);
    if CanF1 and CanF2 then
    begin
      case AOperation of
        voAdd:
        	Result := F1 + F2;
        voSubtract:
        	Result := F1 - F2;
        voMultiply:
        	Result := F1 * F2;
      end;
    end
    else begin
      if CanI1 or CanI2 then
      begin
        if not CanI1 then I1 := ALeft.ToInt;
        if not CanI2 then I2 := ARight.ToInt;
        case AOperation of
          voAdd:
          	Result := I1 + I2;
          voSubtract:
          	Result := I1 - I2;
          voMultiply:
          	Result := I1 * I2;
        end;
      end
      else if CanF1 or CanF2 then
      begin
        if not CanF1 then F1 := ALeft.ToFloat;
        if not CanF2 then F2 := ARight.ToFloat;
        case AOperation of
          voAdd:
          	Result := F1 + F2;
          voSubtract:
          	Result := F1 - F2;
          voMultiply:
          	Result := F1 * F2;
        end;
      end
      else begin
        if not CanI1 then I1 := ALeft.ToInt;
        if not CanI2 then I2 := ARight.ToInt;
        case AOperation of
          voAdd:
          	Result := I1 + I2;
          voSubtract:
          	Result := I1 - I2;
          voMultiply:
          	Result := I1 * I2;
        end;
      end;
    end;
  end;
end;

class function TVariableRecord.DoFloatOp(ALeft, ARight: TVariableRecord;
	AOperation: TBinaryOperation): TVariableRecord;
var
  F1, F2: double;
  CanF1, CanF2: boolean;
begin
  Assert(AOperation = voDivide, 'For voDivide only! (yet)');
  CanF1 := ALeft.CanConvertToFloat(F1);
  CanF2 := ARight.CanConvertToFloat(F2);
  if CanF1 and CanF2 then
    Result := F1 / F2
  else
  begin
    if not CanF1 then
      F1 := ALeft.ToFloat;
    if not CanF2 then
      F2 := ARight.ToFloat;
    if F2 <> 0 then
      Result := F1 / F2
    else
      Result := TVariableRecord.Null;
  end;
end;

class function TVariableRecord.DoIntOp(ALeft, ARight: TVariableRecord;
	AOperation: TBinaryOperation): TVariableRecord;
var
	I1, I2: integer;
  CanI1, CanI2: boolean;
begin
  CanI1 := ALeft.CanConvertToInt(I1);
  CanI2 := ARight.CanConvertToInt(I2);
  if CanI1 and CanI2 then
  begin
    case AOperation of
      voAnd:
      	Result := I1 and I2;
      voOr:
      	Result := I1 or I2;
      voXor:
      	Result := I1 xor I2;
      voIntDivide:
      	Result := I1 div I2;
      voModulus:
      	Result := I1 mod I2;
      voShl:
      	Result := I1 shl I2;
      voShr:
      	Result := I1 shr I2;
    end;
  end
  else begin
    if not CanI1 then I1 := ALeft.ToInt;
    if not CanI2 then I2 := ARight.ToInt;
    case AOperation of
      voAnd:
      	Result := I1 and I2;
      voOr:
      	Result := I1 or I2;
      voXor:
      	Result := I1 xor I2;
      voIntDivide:
      	Result := I1 div I2;
      voModulus:
      	Result := I1 mod I2;
      voShl:
      	Result := I1 shl I2;
      voShr:
      	Result := I1 shr I2;
    end;
  end;
end;

class function TVariableRecord.DoIntNot(ARight: TVariableRecord): TVariableRecord;
begin
	Result := not ARight.ToInt;
end;

class function TVariableRecord.DoLogicalOp(ALeft, ARight: TVariableRecord;
	AOperation: TBinaryOperation): TVariableRecord;
var
	B1, B2: boolean;
  CanB1, CanB2: boolean;
begin
  CanB1 := ALeft.CanConvertToLogical(B1);
  CanB2 := ARight.CanConvertToLogical(B2);
  if CanB1 and CanB2 then
  begin
    case AOperation of
      voAnd:
      	Result := B1 and B2;
      voOr:
      	Result := B1 or B2;
      voXor:
      	Result := B1 xor B2;
    end;
  end
  else begin
    if not CanB1 then B1 := ALeft.ToBool;
    if not CanB2 then B2 := ARight.ToBool;
    case AOperation of
      voAnd:
      	Result := B1 and B2;
      voOr:
      	Result := B1 or B2;
      voXor:
      	Result := B1 xor B2;
    end;
  end;
end;

class function TVariableRecord.DoLogicalNot(ARight: TVariableRecord): TVariableRecord;
begin
	Result := not ARight.ToBool;
end;

class operator TVariableRecord.Add(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntFloatOp(ALeft, ARight, voAdd);
end;

class operator TVariableRecord.Subtract(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntFloatOp(ALeft, ARight, voSubtract);
end;

class operator TVariableRecord.Multiply(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntFloatOp(ALeft, ARight, voMultiply);
end;

class operator TVariableRecord.Divide(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoFloatOp(ALeft, ARight, voDivide);
end;

class operator TVariableRecord.IntDivide(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntOp(ALeft, ARight, voIntDivide);
end;

class operator TVariableRecord.Modulus(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntOp(ALeft, ARight, voModulus);
end;

class operator TVariableRecord.LeftShift(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntOp(ALeft, ARight, voShl);
end;

class operator TVariableRecord.RightShift(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoIntOp(ALeft, ARight, voShr);
end;

class operator TVariableRecord.LogicalAnd(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoLogicalOp(ALeft, ARight, voAnd);
end;

class operator TVariableRecord.LogicalOr(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoLogicalOp(ALeft, ARight, voOr);
end;

class operator TVariableRecord.LogicalXor(ALeft, ARight: TVariableRecord): TVariableRecord;
begin
	DoLogicalOp(ALeft, ARight, voXor);
end;

{************* TVariablePart *************}

procedure TVariablePart.Finalize;
begin
	case Self.PartType of
    vptValue:
    	string(Self.SValue) := '';
  end;
end;

function TVariablePart.Clone: TVariablePart;
begin
  Result.PartType := Self.PartType;
  case Self.PartType of
    vptValue:
    begin
    	Result.SValue := nil;
    	string(Result.SValue) := string(Self.SValue);  
    end;
    vptIndex:
    	Result.IValue := Self.IValue;
  end;
end;

class operator TVariablePart.Implicit(AValue: integer): TVariablePart;
begin
	Result.PartType := vptIndex;
  Result.IValue := AValue;
end;

class operator TVariablePart.Implicit(AValue: string): TVariablePart;
begin
	Result.PartType := vptValue;
  Result.SValue := nil;
  string(Result.SValue) := AValue;
end;

class operator TVariablePart.Implicit(APart: TVariablePart): integer;
begin
	case APart.PartType of
    vptIndex: Result := APart.IValue;
  else
  	Result := -1;
  end;
end;

class operator TVariablePart.Implicit(APart: TVariablePart): string;
begin
	case APart.PartType of
    vptValue: Result := string(APart.SValue);
  else
  	Result := '';
  end;
end;

{************* TVarList *************}

function TVarList.Clone: TVarList;
var
	I: integer;
begin
	Result := TVarList.Create;
 	for I := 0 to Count - 1 do Result.Add(Items[I].Clone);
end;

procedure TVarList.Finalize;
var
	I: integer;
begin
	for I := 0 to Count - 1 do Items[I].Finalize;
  {$IF COMPILERVERSION < 25} // < XE4
  Free;
  {$ELSE}
  DisposeOf;
  {$ENDIF}
end;

procedure TVarList.DeleteElement(Index: integer);
begin
	Items[Index].Finalize;
  Delete(Index);
end;

procedure TVarList.AddArrayPrefix(AVariable: TVarList; Index: integer);
var
	I: integer;
begin
	for I := 0 to AVariable.Count - 1 do
  	Insert(I, AVariable[I]);
  Insert(AVariable.Count, Index);
end;

function TVarList.IsSimpleVariable(out VarName: string): boolean;
begin
	if (Count = 1) and (Items[0].PartType = vptValue) then
  begin
  	VarName := Items[0];
    Result := true;
  end
  else
  	Result := false;
end;

function TVarList.CheckTopLevel(const AName: string): boolean;
begin
	if (Count >= 1) and (Items[0].PartType = vptValue) and
    (CompareText(Items[0], AName) = 0) then
  begin
    Result := true;
    DeleteElement(0);
  end
  else
  	Result := false;
end;

function TVarList.IsTopValueLevel(out AName: string): boolean;
begin
	if (Count >= 1) and (Items[0].PartType = vptValue) then
  begin
  	AName := Items[0];
    Result := true;
    DeleteElement(0);
  end
  else
  	Result := false;
end;

{************* TForEachList *************}

constructor TForEachList.Create;
begin
	inherited Create;
	CurrentRecords := TList<integer>.Create;
end;

destructor TForEachList.Destroy;
var
	I: integer;
begin
  for I := Count - 1 downto 0 do
    {$IF COMPILERVERSION < 25} // < XE4
    Items[I].Free;
    {$ELSE}
    Items[I].DisposeOf;
    {$ENDIF}
	CurrentRecords.Free;
  inherited Destroy;
end;

procedure TForEachList.EnterForEach(AList: TForEachData);
begin
  CurrentRecords.Add(Add(AList));
end;

procedure TForEachList.ExitForEach;
begin
	if (CurrentRecords.Count > 0) then
  	CurrentRecords.Delete(CurrentRecords.Count - 1);
end;

function TForEachList.InForEach: boolean;
begin
	Result := CurrentRecords.Count > 0;
end;

function TForEachList.FindItemRecord(const AItemName: string; out ARecord: TForEachData): boolean;
var
	I: integer;
begin
	Result := false;
	for I := CurrentRecords.Count - 1 downto 0 do
  	if CompareText(AItemName, Items[CurrentRecords[I]].ItemVarName) = 0 then
  	begin
    	ARecord := Items[CurrentRecords[I]];
      Exit(true);
  	end;
end;

function TForEachList.FindKeyRecord(const AKeyName: string; out ARecord: TForEachData): boolean;
var
	I: integer;
begin
	Result := false;
	for I := CurrentRecords.Count - 1 downto 0 do
  	if CompareText(AKeyName, Items[CurrentRecords[I]].KeyVarName) = 0 then
  	begin
    	ARecord := Items[CurrentRecords[I]];
      Exit(true);
  	end;
end;

function TForEachList.FindRecord(const AName: string;
	out ARecord: TForEachData): boolean;
var
	I: integer;
begin
	Result := false;
  if (CompareText(AName, 'current') = 0) and (CurrentRecords.Count > 0) then
  begin
  	ARecord := Items[CurrentRecords[CurrentRecords.Count-1]];
    Result := true;
  end
  else if AName <> '' then
  begin
    for I := 0 to Count - 1 do
      if CompareText(Items[I].Name, AName) = 0 then
      begin
        ARecord := Items[I];
        Exit(true);
      end;
  end;
end;

{************* TCaptureArrayItem *************}

constructor TCaptureArrayItem.Create;
begin
  inherited Create;
  IsActive := false;
  ItemName := '';
  Index := 0;
  VarData := nil;
end;

destructor TCaptureArrayItem.Destroy;
begin
  inherited Destroy;
end;

procedure TCaptureArrayItem.Enter(const AName: string; AIndex: integer; AVarData: PVariableArray);
begin
  IsActive := true;
  ItemName := AName;
  Index := AIndex;
  VarData := AVarData;
end;

procedure TCaptureArrayItem.IncIndex;
begin
  Inc(Index);
end;

procedure TCaptureArrayItem.Exit;
begin
  IsActive := false;
  VarData := nil;
end;

function TCaptureArrayItem.IsItemName(const AName: string): boolean;
begin
  Result := IsActive and (CompareText(ItemName, AName) = 0);
end;


{************* TSmartyProvider *************}

constructor TSmartyProvider.Create(AEngine: TSmartyEngine);
begin
	inherited Create;
  FEngine := AEngine;
  FForEachList := TForEachList.Create;
  FCaptureCache := TList<TCaptureCache>.Create;
  FActiveCapture := TCaptureArrayItem.Create;
end;

destructor TSmartyProvider.Destroy;
begin
  ClearCaptureCache;
  FCaptureCache.Free;
  FForEachList.Free;
  FActiveCapture.Free;
	inherited Destroy;
end;

procedure TSmartyProvider.ClearCaptureCache;
var
  I: integer;
begin
  for I := FCaptureCache.Count - 1 downto 0 do
  begin
    FCaptureCache[I].VariableValue^.Finalize;
    FreeMem(FCaptureCache[I].VariableValue, SizeOf(TVariableRecord));
    FCaptureCache.Delete(I);
  end;
end;

function TSmartyProvider.FindCaptureItem(const AName: string; var Cache: TCaptureCache): boolean;
var
  I: integer;
begin
  Result := false;
  for I := 0 to FCaptureCache.Count - 1 do
  begin
    Cache := FCaptureCache[I];
    if CompareText(Cache.VariableName, AName) = 0 then Exit(true);
  end;
end;

procedure TSmartyProvider.SetCaptureItem(const AName: string; VariableValue: TVariableRecord);
var
  Cache: TCaptureCache;
begin
  if FindCaptureItem(AName, Cache) then
  begin
    Cache.VariableValue^.Finalize;
    Cache.VariableValue^ := VariableValue;
  end
  else begin
    Cache.VariableValue := AllocMem(SizeOf(TVariableRecord));
    Cache.VariableName := AName;
    Cache.VariableValue^ := VariableValue;
    FCaptureCache.Add(Cache);
  end;
end;

procedure TSmartyProvider.RemoveCaptureItem(const AName: string);
var
  Cache: TCaptureCache;
  I: integer;
begin
  for I := 0 to FCaptureCache.Count - 1 do
  begin
    Cache := FCaptureCache[I];
    if CompareText(Cache.VariableName, AName) = 0 then
    begin
      Cache.VariableValue^.Finalize;
      FreeMem(Cache.VariableValue, SizeOf(TVariableRecord));
      FCaptureCache.Delete(I);
      Exit;
    end;
  end;
end;

class function TSmartyProvider.GetName: string;
begin
	Result := 'smarty';
end;

class function TSmartyProvider.IsIndexSupported: boolean;
begin
  Result := false;
end;

class function TSmartyProvider.UseCache: boolean;
begin
  Result := false;
end;

procedure TSmartyProvider.GetIndexProperties(var AMin, AMax: integer);
begin
  AMin := 0;
  AMax := 0;
end;

function TSmartyProvider.GetVariable(AIndex: integer; AVarName: string): TVariableRecord;
begin
	Result :=  TVariableRecord.Null;
end;

function TSmartyProvider.GetSmartyVariable(const AVarName: string;
	AVarDetails: TVarList; var NeedFinalize: boolean): TVariableRecord;
var
	S, VarName: string;
  VarDetails: TVarList;
  FERec: TForEachData;
  CacheRec: TCaptureCache;
begin // FI:C101
	Result :=  TVariableRecord.Null;
  NeedFinalize := true;

	if AVarDetails.Count = 0 then
  begin
		if CompareText(AVarName, 'now') = 0 then Result := Now
		else if CompareText(AVarName, 'ldelim') = 0 then Result := '{'
		else if CompareText(AVarName, 'rdelim') = 0 then Result := '}'
    else if CompareText(AVarName, 'templatedir') = 0 then
    	Result := IncludeTrailingPathDelimiter(FEngine.TemplateFolder);
  end
  else begin
  	if CompareText(AVarName, 'foreach') = 0 then
    begin
      VarDetails := AVarDetails.Clone;
      try
        if VarDetails.IsTopValueLevel(S) and FForEachList.FindRecord(S, FERec) then
        begin
          if VarDetails.CheckTopLevel(FERec.ItemVarName) then
          begin
          	Result := FERec.VarData.Data[FERec.Iteration - 1].Item;
            if VarDetails.Count > 0 then
              Result := FEngine.GetVariableDetails(Result, VarDetails);
            NeedFinalize := false;
          end
          else if VarDetails.IsSimpleVariable(VarName) then
          begin
            if CompareText(VarName, 'total') = 0 then Result := FERec.Total
            else if CompareText(VarName, 'inforeach') = 0 then Result := FERec.InForEach
            else if FERec.InForEach then
              if CompareText(VarName, 'iteration') = 0 then Result := FERec.Iteration
              else if CompareText(VarName, 'start') = 0 then Result := FERec.MinIndex
              else if CompareText(VarName, 'first') = 0 then Result := FERec.First
              else if CompareText(VarName, 'last') = 0 then Result := FERec.Last
              else if CompareText(VarName, 'show') = 0 then Result := FERec.Show
              else if CompareText(VarName, FERec.KeyVarName) = 0 then
              begin
              	Result := string(FERec.VarData.Data[FERec.Iteration - 1].Key);
                NeedFinalize := false;
              end;
          end;
        end;

      finally
        VarDetails.Finalize;
      end;
    end
    else if CompareText(AVarName, 'capture') = 0 then
    begin
      VarDetails := AVarDetails.Clone;
      try
        if VarDetails.IsTopValueLevel(S) and FindCaptureItem(S, CacheRec) then
        begin
          Result := CacheRec.VariableValue^;
          if VarDetails.Count > 0 then
            Result := FEngine.GetVariableDetails(Result, VarDetails);
          NeedFinalize := false;
        end;
      finally
        VarDetails.Finalize;
      end;
    end;
  end;

	NeedFinalize := NeedFinalize and ((Result.VarType = vtString) or (Result.VarType = vtArray));
end;

function TSmartyProvider.GetDetachVariable(const AVarName: string; AVarDetails: TVarList;
	var NeedFinalize: boolean): TVariableRecord;
var
	FERec: TForEachData;
  VName: string;
  VList: TVarList;
begin
  if FActiveCapture.IsActive and FActiveCapture.IsItemName(AVarName) then
  begin
    Result := FActiveCapture.VarData.Data[FActiveCapture.Index].Item;
    if AVarDetails.Count > 0 then
      Result := FEngine.GetVariableDetails(Result, AVarDetails);
    NeedFinalize := false;
  end
	else if FForEachList.InForEach then
  begin
  	if FForEachList.FindItemRecord(AVarName, FERec) then
		begin
      if FERec.IsNamespace then
      begin
        VList := AVarDetails.Clone;
        try
          if VList.IsTopValueLevel(VName) then
            Result := FEngine.GetVariable(FERec.Namespace, FERec.MinIndex + FERec.Iteration - 1,
              VName, VList, NeedFinalize)
          else
            Result := TVariableRecord.Null;
        finally
          VList.Finalize;
        end;
      end
      else begin
        Result := FERec.VarData.Data[FERec.Iteration - 1].Item;
        if AVarDetails.Count > 0 then
          Result := FEngine.GetVariableDetails(Result, AVarDetails);
        NeedFinalize := false;
      end;
    end
    else if FForEachList.FindKeyRecord(AVarName, FERec) and (AVarDetails.Count = 0) then
    begin
    	Result := string(FERec.VarData.Data[FERec.Iteration - 1].Key);
      NeedFinalize := true;
    end
    else
    	Result :=  TVariableRecord.Null;
  end
  else
  	Result :=  TVariableRecord.Null;

	NeedFinalize := NeedFinalize and ((Result.VarType = vtString) or (Result.VarType = vtArray));
end;

{************* TVariableModifier *************}

class function TVariableModifier.CheckParams(AModifier: TVariableModifierClass;
	AParams: TStringList; AMin, AMax: integer): boolean;
var
	Cnt: integer;
begin
	if Assigned(AParams) then Cnt := AParams.Count else Cnt := 0;
  Result := (AMin <= Cnt) and (Cnt <= AMax);
  if not Result then
  	raise ESmartyException.CreateResFmt(@sInvalidParameters,
    	[Cnt, AMin, AMax, AModifier.GetName]);
end;

class function TVariableModifier.SetParam(AParams: TStringList; AIndex: integer;
	var Value: string): boolean;
begin
	Result := false;
	if Assigned(AParams) then
  	if AIndex  < AParams.Count then
    begin
    	Value := AParams[AIndex];
    	Result := true;
    end;
end;

class procedure TVariableModifier.ModifyVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	I: integer;
  ArrayData: PVariableArray;
begin
  if AVariable.IsArray then
  begin
  	ArrayData := AVariable.AValue;
    if ArrayData.Count > 0 then
    	for I := 0 to ArrayData.Count - 1 do
      	ModifyVariable(ArrayData.Data[I].Item, AParams);
  end
  else
  	ModVariable(AVariable, AParams);
end;

{************* TCapitalizeModifier *************}

class function TCapitalizeModifier.GetName: string;
begin
	Result := 'capitalize';
end;

class function TCapitalizeModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TCapitalizeModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	CapitalizeNumbers: boolean;
  B: boolean;
  S: string;
begin
	CapitalizeNumbers := false;
  if CheckParams(Self, AParams, 0, 1) and SetParam(AParams, 0, S) and TryStringToBool(S, B) then
    CapitalizeNumbers := B;

  AVariable.SetString(UCWords(AVariable.ToString, CapitalizeNumbers));
end;

{************* TCatModifier *************}

class function TCatModifier.GetName: string;
begin
	Result := 'cat';
end;

class function TCatModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TCatModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	Add: string;
begin
	Add := '';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, Add);
  AVariable.SetString(AVariable.ToString + Add);
end;

{************* TTrimModifier *************}

class function TTrimModifier.GetName: string;
begin
	Result := 'trim';
end;

class function TTrimModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TTrimModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	Mode: string;
begin
	Mode := 'all';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, Mode);
  if CompareText('left', Mode) = 0 then
    AVariable.SetString(SmartyTrimLeft(AVariable.ToString))
  else if CompareText('right', Mode) = 0 then
    AVariable.SetString(SmartyTrimRight(AVariable.ToString))
  else
    AVariable.SetString(SmartyTrim(AVariable.ToString));
end;

{************* TCountCharactersModifier *************}

class function TCountCharactersModifier.GetName: string;
begin
	Result := 'count_characters';
end;

class function TCountCharactersModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TCountCharactersModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	CountWhitespace: boolean;
  B: boolean;
  S: string;
begin
	CountWhitespace := false;
  if CheckParams(Self, AParams, 0, 1) and SetParam(AParams, 0, S) and TryStringToBool(S, B) then
    CountWhitespace := B;

  AVariable.SetInt(CountCharacters(AVariable.ToString, CountWhitespace));
end;

{************* TCountParagraphsModifier *************}

class function TCountParagraphsModifier.GetName: string;
begin
	Result := 'count_paragraphs';
end;

class function TCountParagraphsModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TCountParagraphsModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
  AVariable.SetInt(CountParagraphs(AVariable.ToString));
end;

{************* TCountWordsModifier *************}

class function TCountWordsModifier.GetName: string;
begin
	Result := 'count_words';
end;

class function TCountWordsModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TCountWordsModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
  AVariable.SetInt(CountWords(AVariable.ToString));
end;

{************* TDefaultModifier *************}

class function TDefaultModifier.GetName: string;
begin
	Result := 'default';
end;

class function TDefaultModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TDefaultModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	DefValue: string;
begin
  DefValue := '';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, DefValue);

  case AVariable.VarType of
    vtNull:
    	AVariable.SetString(DefValue);
    vtString:
      if string(AVariable.SValue) = '' then AVariable.SetString(DefValue);
  end;
end;

{************* THTMLEncodeModifier *************}

class function THTMLEncodeModifier.GetName: string;
begin
	Result := 'html_encode';
end;

class function THTMLEncodeModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure THTMLEncodeModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
	AVariable.SetString(HTMLEncode(AVariable.ToString));
end;

{************* THTMLEncodeAllModifier *************}

class function THTMLEncodeAllModifier.GetName: string;
begin
	Result := 'html_encode_all';
end;

class function THTMLEncodeAllModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure THTMLEncodeAllModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
	AVariable.SetString(HTMLEncodeEntities(AVariable.ToString));
end;

{************* TXMLEncodeModifier *************}

class function TXMLEncodeModifier.GetName: string;
begin
	Result := 'xml_encode';
end;

class function TXMLEncodeModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TXMLEncodeModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
	AVariable.SetString(XMLEncode(AVariable.ToString));
end;

{************* TFileEncodeModifier *************}

class function TFileEncodeModifier.GetName: string;
begin
	Result := 'file_encode';
end;

class function TFileEncodeModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TFileEncodeModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
	AVariable.SetString(FileEncode(AVariable.ToString));
end;

{************* TDateFormatModifier *************}

class function TDateFormatModifier.GetName: string;
begin
	Result := 'date_format';
end;

class function TDateFormatModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TDateFormatModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	S, DateFormat: string;
  DT: TDateTime;
begin
  DateFormat := '';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, DateFormat);

  if CompareText(DateFormat, 'shortdate') = 0 then DateFormat := FormatSettings.ShortDateFormat
  else if CompareText(DateFormat, 'longdate') = 0 then DateFormat := FormatSettings.LongDateFormat
  else if CompareText(DateFormat, 'shorttime') = 0 then DateFormat := FormatSettings.ShortTimeFormat
  else if CompareText(DateFormat, 'longtime') = 0 then DateFormat := FormatSettings.LongTimeFormat;

  case AVariable.VarType of
    vtNull, vtBoolean:
    begin
      AVariable.SetNull;
      Exit;
    end;
    vtInteger:
    begin
      DT := AVariable.IValue;
      if DateFormat = '' then DateFormat := FormatSettings.ShortDateFormat;
    end;
    vtFloat: 
    	DT := AVariable.FValue;
    vtDateStrict:
    begin
      DT := AVariable.DSValue;
      if DateFormat = '' then DateFormat := FormatSettings.ShortDateFormat;
    end;
    vtDateLoose:
    begin
      DT := DateTimeFromRecord(AVariable.DLValue);
      if DateFormat = '' then DateFormat := FormatSettings.ShortDateFormat;
    end;
    vtDateTime:
    	DT := AVariable.DTValue;
    vtString:
      if not TryStrToDate(string(AVariable.SValue), DT) or
        not TryStrToTime(string(AVariable.SValue), DT) or
        not TryStrToDateTime(string(AVariable.SValue), DT) then
      begin
        AVariable.SetNull;
        Exit;
      end;
  end;

  DateTimeToString(S, DateFormat, DT);
  AVariable.SetString(S);
end;


{************* TFloatFormatModifier *************}

class function TFloatFormatModifier.GetName: string;
begin
	Result := 'float_format';
end;

class function TFloatFormatModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TFloatFormatModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	Format: string;
begin
  Format := '';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, Format);

  AVariable.SetString(FormatFloat(Format, AVariable.ToFloat));
end;

{************* TLowerModifier *************}

class function TLowerModifier.GetName: string;
begin
	Result := 'lower';
end;

class function TLowerModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TLowerModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
  AVariable.SetString(AnsiLowerCase(AVariable.ToString));
end;

{************* TUpperModifier *************}

class function TUpperModifier.GetName: string;
begin
	Result := 'upper';
end;

class function TUpperModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TUpperModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
begin
  AVariable.SetString(AnsiUpperCase(AVariable.ToString));
end;

{************* TNl2BrModifier *************}

class function TNl2BrModifier.GetName: string;
begin
	Result := 'nl2br';
end;

class function TNl2BrModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 0);
end;

class procedure TNl2BrModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
  S: string;
begin
	S := AVariable.ToString;
  S := StringReplace(S, sLineBreak, '<br/>', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, #13, '<br/>', [rfReplaceAll, rfIgnoreCase]);
  S := StringReplace(S, #10, '<br/>', [rfReplaceAll, rfIgnoreCase]);
  AVariable.SetString(S);
end;

{************* TTruncateModifier *************}

class function TTruncateModifier.GetName: string;
begin
	Result := 'truncate';
end;

class function TTruncateModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 4);
end;

class procedure TTruncateModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
  Length, I: integer;
  S, Etc: string;
  BreakWords, Middle, B: boolean;
begin
  Length := 80;
  Etc := '...';
  BreakWords := false;
  Middle := false;

  if CheckParams(Self, AParams, 0, 4) then
  begin
    if SetParam(AParams, 0, S) and TryStrToInt(S, I) and (I > 0) then Length := I;
    SetParam(AParams, 1, Etc);
    if SetParam(AParams, 2, S) and TryStringToBool(S, B) then BreakWords := B;
    if SetParam(AParams, 3, S) and TryStringToBool(S, B) then Middle := B;
  end;

  AVariable.SetString(TruncateString(AVariable.ToString, Length, Etc, BreakWords, Middle));
end;

{************* TStripModifier *************}

class function TStripModifier.GetName: string;
begin
	Result := 'strip';
end;

class function TStripModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TStripModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	StripStr: string;
begin
  StripStr := ' ';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, StripStr);

  AVariable.SetString(Strip(AVariable.ToString, StripStr));
end;

{************* TSpacifyModifier *************}

class function TSpacifyModifier.GetName: string;
begin
	Result := 'spacify';
end;

class function TSpacifyModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 1);
end;

class procedure TSpacifyModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
	StripStr: string;
begin
  StripStr := ' ';
  if CheckParams(Self, AParams, 0, 1) then SetParam(AParams, 0, StripStr);

  AVariable.SetString(Spacify(AVariable.ToString, StripStr));
end;

{************* TWordwrapModifier *************}

class function TWordwrapModifier.GetName: string;
begin
	Result := 'wordwrap';
end;

class function TWordwrapModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 2);
end;

class procedure TWordwrapModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
  MaxCol, I: integer;
  S, BreakStr: string;
begin
  MaxCol := 80;
  BreakStr := sLineBreak;

  if CheckParams(Self, AParams, 0, 2) then
  begin
    if SetParam(AParams, 0, S) and TryStrToInt(S, I) and (I > 0) then MaxCol := I;
    SetParam(AParams, 1, BreakStr);
  end;

  AVariable.SetString(Wordwrap(AVariable.ToString, MaxCol, BreakStr));
end;

{************* TIndentModifier *************}

class function TIndentModifier.GetName: string;
begin
	Result := 'indent';
end;

class function TIndentModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 2);
end;

class procedure TIndentModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
  IndentCount, I: integer;
  S, IndentStr: string;
begin
  IndentCount := 4;
  IndentStr := ' ';

  if CheckParams(Self, AParams, 0, 2) then
  begin
    if SetParam(AParams, 0, S) and TryStrToInt(S, I) and (I > 0) then IndentCount := I;
    SetParam(AParams, 1, IndentStr);
  end;

  S := '';
  for I := 1 to IndentCount do // FI:W528
    S := S + IndentStr;

  AVariable.SetString(IndentString(AVariable.ToString, S));
end;

{************* TReplaceModifier *************}

class function TReplaceModifier.GetName: string;
begin
	Result := 'replace';
end;

class function TReplaceModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 2, 3);
end;

class procedure TReplaceModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
  ReplaceFrom, ReplaceTo, S: string;
  B, CaseSensitive: boolean;
begin
  ReplaceFrom := '';
  ReplaceTo := '';
  CaseSensitive := false;

  if CheckParams(Self, AParams, 2, 3) then
  begin
    SetParam(AParams, 0, ReplaceFrom);
    SetParam(AParams, 1, ReplaceTo);
    if SetParam(AParams, 2, S) and TryStringToBool(S, B) then CaseSensitive := B;
  end;

  if CaseSensitive then
    AVariable.SetString(AnsiReplaceStr(AVariable.ToString, ReplaceFrom, ReplaceTo))
  else
    AVariable.SetString(AnsiReplaceText(AVariable.ToString, ReplaceFrom, ReplaceTo));
end;

{************* TStripTagsModifier *************}

class function TStripTagsModifier.GetName: string;
begin
	Result := 'strip_tags';
end;

class function TStripTagsModifier.CheckInputParams(AParams: TStringList): boolean;
begin
	Result := CheckParams(Self, AParams, 0, 2);
end;

class procedure TStripTagsModifier.ModVariable(const AVariable: TVariableRecord;
	AParams: TStringList);
var
  NoSpace, ParseTags, B: boolean;
  S: string;
begin
  NoSpace := false;
  ParseTags := false;

  if CheckParams(Self, AParams, 0, 4) then
  begin
    if SetParam(AParams, 0, S) and TryStringToBool(S, B) then NoSpace := B;
    if SetParam(AParams, 1, S) and TryStringToBool(S, B) then ParseTags := B;
  end;

  AVariable.SetString(StripTags(AVariable.ToString, NoSpace, ParseTags));
end;

{************* TSmartyFunction *************}

class function TSmartyFunction.IsParam(Index: integer;
	AParams: array of TVariableRecord; var Param: TVariableRecord): boolean;
begin
	Result := (Index >= 0) and (Index < Length(AParams));
	if Result then Param := AParams[Index];
end;

class function TSmartyFunction.GetParam(Index: integer;
	AParams: array of TVariableRecord): TVariableRecord;
begin
	if (Index >= 0) and (Index < Length(AParams)) then
  	Result := AParams[Index]
  else
  	Result := TVariableRecord.Null;
end;

class function TSmartyFunction.EvaluateFunction(AParams: array of TVariableRecord): TVariableRecord;
begin
	if CheckParams(Length(AParams)) then
		Result := Evaluate(AParams)
  else
  	Result := TVariableRecord.Null;
end;

{************* TIsNullFunction *************}

class function TIsNullFunction.GetName: string;
begin
  Result := 'is_null';
end;

class function TIsNullFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsNullFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsNull;
end;

{************* TIsEmptyFunction *************}

class function TIsEmptyFunction.GetName: string;
begin
  Result := 'is_empty';
end;

class function TIsEmptyFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsEmptyFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsEmpty;
end;

{************* TIsBooleanFunction *************}

class function TIsBooleanFunction.GetName: string;
begin
  Result := 'is_bool';
end;

class function TIsBooleanFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsBooleanFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsBoolean;
end;

{************* TIsIntegerFunction *************}

class function TIsIntegerFunction.GetName: string;
begin
  Result := 'is_int';
end;

class function TIsIntegerFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsIntegerFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsInteger;
end;

{************* TIsFloatFunction *************}

class function TIsFloatFunction.GetName: string;
begin
  Result := 'is_float';
end;

class function TIsFloatFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsFloatFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsFloat;
end;

{************* TIsNumberFunction *************}

class function TIsNumberFunction.GetName: string;
begin
  Result := 'is_number';
end;

class function TIsNumberFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsNumberFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsNumber;
end;

{************* TIsDateStrictFunction *************}

class function TIsDateStrictFunction.GetName: string;
begin
  Result := 'is_datestrict';
end;

class function TIsDateStrictFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsDateStrictFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsDateStrict;
end;

{************* TIsDateLooseFunction *************}

class function TIsDateLooseFunction.GetName: string;
begin
  Result := 'is_dateloose';
end;

class function TIsDateLooseFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsDateLooseFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsDateLoose;
end;

{************* TIsDateTimeFunction *************}

class function TIsDateTimeFunction.GetName: string;
begin
  Result := 'is_datetime';
end;

class function TIsDateTimeFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsDateTimeFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsDateTime;
end;

{************* TIsDateFunction *************}

class function TIsDateFunction.GetName: string;
begin
  Result := 'is_date';
end;

class function TIsDateFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsDateFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsDate;
end;

{************* TIsStringFunction *************}

class function TIsStringFunction.GetName: string;
begin
  Result := 'is_string';
end;

class function TIsStringFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsStringFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsString;
end;

{************* TIsArrayFunction *************}

class function TIsArrayFunction.GetName: string;
begin
  Result := 'is_array';
end;

class function TIsArrayFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TIsArrayFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).IsArray;
end;

{************* TArrayLengthFunction *************}

class function TArrayLengthFunction.GetName: string;
begin
  Result := 'array_length';
end;

class function TArrayLengthFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TArrayLengthFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V: TVariableRecord;
begin
	V := GetParam(0, AParams);
	case V.VarType of
    vtArray:
    	Result := PVariableArray(V.AValue).Count;
  else
  	Result := 0;
  end;
end;

{************* TArrayIndexFunction *************}

class function TArrayIndexFunction.GetName: string;
begin
  Result := 'array_index';
end;

class function TArrayIndexFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 2);
end;

class function TArrayIndexFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V1, V2: TVariableRecord;
  I: integer;
begin
	V1 := GetParam(0, AParams);
  V2 := GetParam(1, AParams);
	case V1.VarType of
    vtArray:
    begin
      I := V2.ToInt;
      if (I >= 0) and (I < PVariableArray(V1.AValue).Count) then
        Result := PVariableArray(V1.AValue).Data[I].Item.Clone
      else
        Result := TVariableRecord.Null;
    end;
  else
  	Result := TVariableRecord.Null;
  end;
end;

{************* TArrayKeyFunction *************}

class function TArrayKeyFunction.GetName: string;
begin
  Result := 'array_key';
end;

class function TArrayKeyFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 2);
end;

class function TArrayKeyFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V1, V2: TVariableRecord;
  I: integer;
  S: string;
begin
  Result := TVariableRecord.Null;
	V1 := GetParam(0, AParams);
  V2 := GetParam(1, AParams);
	if V1.VarType = vtArray then
  begin
    S := V2.ToString;
    if S <> '' then
    begin
      for I := 0 to PVariableArray(V1.AValue).Count - 1 do
        if CompareText(string(PVariableArray(V1.AValue).Data[I].Key), S) = 0 then
        begin
          Result := PVariableArray(V1.AValue).Data[I].Item.Clone;
          Break;
        end;
    end
  end;
end;

{************* TCountFunction *************}

class function TCountFunction.GetName: string;
begin
  Result := 'count';
end;

class function TCountFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TCountFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V: TVariableRecord;
begin
	V := GetParam(0, AParams);
	case V.VarType of
    vtArray:
    	Result := PVariableArray(V.AValue).Count;
  else
  	Result := 0;
  end;
end;

{************* TEchoFunction *************}

class function TEchoFunction.GetName: string;
begin
  Result := 'echo';
end;

class function TEchoFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TEchoFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := GetParam(0, AParams).Clone;
end;

{************* TPrintFunction *************}

class function TPrintFunction.GetName: string;
begin
  Result := 'print';
end;

class function TPrintFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 0);
end;

class function TPrintFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	I: integer;
  S: string;
begin
	S := '';
	for I := 0 to High(AParams) do S := S + AParams[I].ToString;
  Result := S;
end;

{************* THTMLEncodeFunction *************}

class function THTMLEncodeFunction.GetName: string;
begin
  Result := 'html_encode';
end;

class function THTMLEncodeFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function THTMLEncodeFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := HTMLEncode(GetParam(0, AParams).ToString);
end;

{************* THTMLEncodeAllFunction *************}

class function THTMLEncodeAllFunction.GetName: string;
begin
  Result := 'html_encode_all';
end;

class function THTMLEncodeAllFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function THTMLEncodeAllFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := HTMLEncodeEntities(GetParam(0, AParams).ToString);
end;

{************* TXMLEncodeFunction *************}

class function TXMLEncodeFunction.GetName: string;
begin
  Result := 'xml_encode';
end;

class function TXMLEncodeFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TXMLEncodeFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := XMLEncode(GetParam(0, AParams).ToString);
end;

{************* TFileEncodeFunction *************}

class function TFileEncodeFunction.GetName: string;
begin
  Result := 'file_encode';
end;

class function TFileEncodeFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TFileEncodeFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := FileEncode(GetParam(0, AParams).ToString);
end;

{************* TTrimFunction *************}

class function TTrimFunction.GetName: string;
begin
  Result := 'trim';
end;

class function TTrimFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TTrimFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  S, Mode: string;
  VR: TVariableRecord;
begin
  S := GetParam(0, AParams).ToString;
  VR := GetParam(1, AParams);
  if VR.IsNull then
    Result := SmartyTrim(S)
  else begin
    Mode := VR.ToString;
    if CompareText(Mode, 'left') = 0 then
      Result := SmartyTrimLeft(S)
    else if CompareText(Mode, 'right') = 0 then
      Result := SmartyTrimRight(S)
    else
      Result := SmartyTrim(S);
  end;
end;

{************* TTruncateFunction *************}

class function TTruncateFunction.GetName: string;
begin
  Result := 'truncate';
end;

class function TTruncateFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 5);
end;

class function TTruncateFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  S, Etc: string;
  L: integer;
  VR: TVariableRecord;
  BreakWords, Middle: boolean;
begin
  S := GetParam(0, AParams).ToString;
  VR := GetParam(1, AParams);
  if VR.IsNull then L := 80 else L := VR.ToInt;
  VR := GetParam(2, AParams);
  if VR.IsNull then Etc := '...' else Etc := VR.ToString;
  VR := GetParam(3, AParams);
  if VR.IsNull then BreakWords := false else BreakWords := VR.ToBool;
  VR := GetParam(4, AParams);
  if VR.IsNull then Middle := false else Middle := VR.ToBool;

  Result := TruncateString(S, L, Etc, BreakWords, Middle);
end;

{************* TStripFunction *************}

class function TStripFunction.GetName: string;
begin
  Result := 'strip';
end;

class function TStripFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TStripFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  StripStr: string;
  VR: TVariableRecord;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then
    StripStr := ' '
  else
    StripStr := VR.ToString;

  Result := Strip(GetParam(0, AParams).ToString, StripStr);
end;

{************* TStripTagsFunction *************}

class function TStripTagsFunction.GetName: string;
begin
  Result := 'strip_tags';
end;

class function TStripTagsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 3);
end;

class function TStripTagsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  NoSpace, ParseTags: boolean;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then NoSpace := true else NoSpace := VR.ToBool;
  VR := GetParam(2, AParams);
  if VR.IsNull then ParseTags := true else ParseTags := VR.ToBool;

  Result := StripTags(GetParam(0, AParams).ToString, NoSpace, ParseTags);
end;

{************* TSpacifyFunction *************}

class function TSpacifyFunction.GetName: string;
begin
  Result := 'spacify';
end;

class function TSpacifyFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TSpacifyFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  StripStr: string;
  VR: TVariableRecord;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then
    StripStr := ' '
  else
    StripStr := VR.ToString;

  Result := Spacify(GetParam(0, AParams).ToString, StripStr);
end;

{************* TWordwrapFunction *************}

class function TWordwrapFunction.GetName: string;
begin
  Result := 'wordwrap';
end;

class function TWordwrapFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 3);
end;

class function TWordwrapFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  MaxCol: integer;
  BreakStr: string;
  VR: TVariableRecord;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then
    MaxCol := 80
  else
    MaxCol := VR.ToInt;

  VR := GetParam(2, AParams);
  if VR.IsNull then
    BreakStr := sLineBreak
  else
    BreakStr := VR.ToString;


  Result := Wordwrap(GetParam(0, AParams).ToString, MaxCol, BreakStr);
end;

{************* TIndentFunction *************}

class function TIndentFunction.GetName: string;
begin
  Result := 'indent';
end;

class function TIndentFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 3);
end;

class function TIndentFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  I, IndentCount: integer;
  S, IndentStr: string;
  VR: TVariableRecord;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then
    IndentCount := 80
  else
    IndentCount := VR.ToInt;

  VR := GetParam(2, AParams);
  if VR.IsNull then
    IndentStr := sLineBreak
  else
    IndentStr := VR.ToString;

  S := '';
  if IndentCount >= 1 then
    for I := 1 to IndentCount do S := S + IndentStr; // FI:W528

  Result := IndentString(GetParam(0, AParams).ToString, S);
end;

{************* TCapitalizeFunction *************}

class function TCapitalizeFunction.GetName: string;
begin
  Result := 'capitalize';
end;

class function TCapitalizeFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TCapitalizeFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  Digits: boolean;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then Digits := false else Digits := VR.ToBool;
  Result := UCWords(GetParam(0, AParams).ToString, Digits);
end;

{************* TCountCharactersFunction *************}

class function TCountCharactersFunction.GetName: string;
begin
  Result := 'count_characters';
end;

class function TCountCharactersFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TCountCharactersFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  CountWhitespace: boolean;
begin
  VR := GetParam(1, AParams);
  if VR.IsNull then CountWhitespace := false else CountWhitespace := VR.ToBool;
  Result := CountCharacters(GetParam(0, AParams).ToString, CountWhitespace);
end;

{************* TCountWordsFunction *************}

class function TCountWordsFunction.GetName: string;
begin
  Result := 'count_words';
end;

class function TCountWordsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TCountWordsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := CountWords(GetParam(0, AParams).ToString);
end;

{************* TCountParagraphsFunction *************}

class function TCountParagraphsFunction.GetName: string;
begin
  Result := 'count_paragraphs';
end;

class function TCountParagraphsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TCountParagraphsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := CountParagraphs(GetParam(0, AParams).ToString);
end;

{************* TUpperCaseFunction *************}

class function TUpperCaseFunction.GetName: string;
begin
  Result := 'upper_case';
end;

class function TUpperCaseFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TUpperCaseFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := AnsiUpperCase(GetParam(0, AParams).ToString);
end;

{************* TLowerCaseFunction *************}

class function TLowerCaseFunction.GetName: string;
begin
  Result := 'lower_case';
end;

class function TLowerCaseFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TLowerCaseFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
	Result := AnsiLowerCase(GetParam(0, AParams).ToString);
end;

{************* TResemblesFunction *************}

class function TResemblesFunction.GetName: string;
begin
  Result := 'resembles';
end;

class function TResemblesFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 2);
end;

class function TResemblesFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  Result := AnsiResemblesText(GetParam(0, AParams).ToString, GetParam(1, AParams).ToString);
end;

{************* TContainsFunction *************}

class function TContainsFunction.GetName: string;
begin
  Result := 'contains';
end;

class function TContainsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 2) and (AParamsCount <= 3);
end;

class function TContainsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  CaseSensitive: boolean;
begin
  VR := GetParam(2, AParams);
  if VR.IsNull then CaseSensitive := false else CaseSensitive := VR.ToBool;

  if CaseSensitive then
    Result := AnsiContainsStr(GetParam(0, AParams).ToString, GetParam(1, AParams).ToString)
  else
    Result := AnsiContainsText(GetParam(0, AParams).ToString, GetParam(1, AParams).ToString);
end;

{************* TStartsFunction *************}

class function TStartsFunction.GetName: string;
begin
  Result := 'stars';
end;

class function TStartsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 2) and (AParamsCount <= 3);
end;

class function TStartsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  CaseSensitive: boolean;
begin
  VR := GetParam(2, AParams);
  if VR.IsNull then CaseSensitive := false else CaseSensitive := VR.ToBool;

  if CaseSensitive then
    Result := AnsiStartsStr(GetParam(1, AParams).ToString, GetParam(0, AParams).ToString)
  else
    Result := AnsiStartsText(GetParam(1, AParams).ToString, GetParam(0, AParams).ToString);
end;

{************* TEndsFunction *************}

class function TEndsFunction.GetName: string;
begin
  Result := 'ends';
end;

class function TEndsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 2) and (AParamsCount <= 3);
end;

class function TEndsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  CaseSensitive: boolean;
begin
  VR := GetParam(2, AParams);
  if VR.IsNull then CaseSensitive := false else CaseSensitive := VR.ToBool;

  if CaseSensitive then
    Result := AnsiEndsStr(GetParam(1, AParams).ToString, GetParam(0, AParams).ToString)
  else
    Result := AnsiEndsText(GetParam(1, AParams).ToString, GetParam(0, AParams).ToString);
end;

{************* TReplaceFunction *************}

class function TReplaceFunction.GetName: string;
begin
  Result := 'replace';
end;

class function TReplaceFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 3) and (AParamsCount <= 4);
end;

class function TReplaceFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  VR: TVariableRecord;
  CaseSensitive: boolean;
begin
  VR := GetParam(3, AParams);
  if VR.IsNull then CaseSensitive := false else CaseSensitive := VR.ToBool;

  if CaseSensitive then
    Result := AnsiReplaceStr(GetParam(0, AParams).ToString,
      GetParam(1, AParams).ToString,
      GetParam(2, AParams).ToString)
  else
    Result := AnsiReplaceText(GetParam(0, AParams).ToString,
      GetParam(1, AParams).ToString,
      GetParam(2, AParams).ToString);
end;

{************* TFloatFormatFunction *************}

class function TFloatFormatFunction.GetName: string;
begin
  Result := 'float_format';
end;

class function TFloatFormatFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TFloatFormatFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
  V: TVariableRecord;
  Format: string;
begin
  V := GetParam(1, AParams);
  if V.VarType = vtNull then
    Format := ''
  else
    Format := V.ToString;

	Result := FormatFloat(Format, GetParam(0, AParams).ToFloat);
end;

{************* TIfThenFunction *************}

class function TIfThenFunction.GetName: string;
begin
  Result := 'ifthen';
end;

class function TIfThenFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 3);
end;

class function TIfThenFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
begin
  if GetParam(0, AParams).ToBool then
    Result := GetParam(1, AParams).Clone
  else
    Result := GetParam(2, AParams).Clone;
end;

{************* TDateFormatFunction *************}

class function TDateFormatFunction.GetName: string;
begin
  Result := 'date_format';
end;

class function TDateFormatFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TDateFormatFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V: TVariableRecord;
  DT: TDateTime;
	S, DateFormat: string;
begin
  V := GetParam(1, AParams);
  if V.IsNull then
    DateFormat := ''
  else
    DateFormat := V.ToString;

  if CompareText(DateFormat, 'shortdate') = 0 then DateFormat := FormatSettings.ShortDateFormat
  else if CompareText(DateFormat, 'longdate') = 0 then DateFormat := FormatSettings.LongDateFormat
  else if CompareText(DateFormat, 'shorttime') = 0 then DateFormat := FormatSettings.ShortTimeFormat
  else if CompareText(DateFormat, 'longtime') = 0 then DateFormat := FormatSettings.LongTimeFormat;

	V := GetParam(0, AParams);

  case V.VarType of
    vtNull, vtBoolean:
      Exit(TVariableRecord.Null);
    vtInteger:
    begin
      DT := V.IValue;
      if DateFormat = '' then DateFormat := FormatSettings.ShortDateFormat;
    end;
    vtFloat:
    	DT := V.FValue;
    vtDateStrict:
    begin
      DT := V.DSValue;
      if DateFormat = '' then DateFormat := FormatSettings.ShortDateFormat;
    end;
    vtDateLoose:
    begin
      DT := DateTimeFromRecord(V.DLValue);
      if DateFormat = '' then DateFormat := FormatSettings.ShortDateFormat;
    end;
    vtDateTime:
    	DT := V.DTValue;
    vtString:
      if not TryStrToDate(string(V.SValue), DT) or
        not TryStrToTime(string(V.SValue), DT) or
        not TryStrToDateTime(string(V.SValue), DT) then
        Exit(TVariableRecord.Null);
  end;

  DateTimeToString(S, DateFormat, DT);
  Result := S;
end;

{************* TFullYearsFunction *************}

class function TFullYearsFunction.GetName: string;
begin
  Result := 'full_years';
end;

class function TFullYearsFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount >= 1) and (AParamsCount <= 2);
end;

class function TFullYearsFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V1, V2: TVariableRecord;
  DLFrom, DLTo: TDateRecord;
  DT: TDateTime;
  Years: integer;
begin // FI:C101
	V1 := GetParam(0, AParams);
  case V1.VarType of
    vtInteger:
    	DLFrom := DateTimeToRecord(V1.IValue);
    vtFloat:
    	DLFrom := DateTimeToRecord(V1.FValue);
    vtDateStrict:
    	DLFrom := DateTimeToRecord(V1.DSValue);
    vtDateLoose:
    	DLFrom := V1.DLValue;
    vtDateTime:
    	DLFrom := DateTimeToRecord(V1.DTValue);
    vtString:
      if TryStrToDateTime(string(V1.SValue), DT) then
        DLFrom := DateTimeToRecord(DT)
      else
        Exit(TVariableRecord.Null);
  else
  	Exit(TVariableRecord.Null);
  end;

  V2 := GetParam(1, AParams);
  case V2.VarType of
    vtInteger:
      DLTo := DateTimeToRecord(V2.IValue);
    vtFloat:
      DLTo := DateTimeToRecord(V2.FValue);
    vtDateStrict:
      DLTo := DateTimeToRecord(V2.DSValue);
    vtDateLoose:
      DLTo := V2.DLValue;
    vtDateTime:
      DLTo := DateTimeToRecord(V2.DTValue);
    vtString:
      if TryStrToDateTime(string(V2.SValue), DT) then
        DLTo := DateTimeToRecord(DT)
      else
        DLTo := DateTimeToRecord(Now);
  else
    DLTo := DateTimeToRecord(Now);
  end;

  if (DLFrom.Year <> 0) and (DLTo.Year <> 0) then
  begin
    if (DLFrom.Month = 0) or (DLTo.Month = 0) then
      Years := 0
    else begin
      if DLTo.Month > DLFrom.Month then
        Years := 0
      else if DLTo.Month < DLFrom.Month then
        Years := -1
      else begin
        // DLTo.Month = DLFrom.Month
        if (DLFrom.Day = 0) or (DLTo.Day = 0) then
          Years := 0
        else begin
          if DLTo.Day >= DLFrom.Day then
            Years := 0
          else
            Years := -1
        end;
      end;
    end;

    Years := DLTo.Year - DLFrom.Year + Years;
    if Years >= 0 then
      Result := Years
    else
      Result := TVariableRecord.Null;
  end
  else
    Result := TVariableRecord.Null;
end;

{************* TYearOfFunction *************}

class function TYearOfFunction.GetName: string;
begin
  Result := 'year_of';
end;

class function TYearOfFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TYearOfFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V: TVariableRecord;
  DT: TDateTime;
begin
	V := GetParam(0, AParams);
  case V.VarType of
    vtBoolean:
      if V.BValue then
      	Result := YearOf(Now)
      else
      	Result := 0;
    vtInteger:
    	Result := YearOf(V.IValue);
    vtFloat:
    	Result := YearOf(V.FValue);
    vtDateStrict:
    	Result := YearOf(V.DSValue);
    vtDateLoose:
    	Result := V.DLValue.Year;
    vtDateTime:
    	Result := YearOf(V.DTValue);
    vtString:
      if TryStrToDateTime(string(V.SValue), DT) then
        Result := YearOf(DT)
      else
        Result := 0;
    vtArray:
    	Result := 0;
  else
  	Result := 0;
  end;
end;

{************* TMonthOfFunction *************}

class function TMonthOfFunction.GetName: string;
begin
  Result := 'month_of';
end;

class function TMonthOfFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TMonthOfFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V: TVariableRecord;
  DT: TDateTime;
begin
	V := GetParam(0, AParams);
  case V.VarType of
    vtBoolean:
      if V.BValue then
      	Result := MonthOf(Now)
      else
      	Result := 0;
    vtInteger:
    	Result := MonthOf(V.IValue);
    vtFloat:
    	Result := MonthOf(V.FValue);
    vtDateStrict:
    	Result := MonthOf(V.DSValue);
    vtDateLoose:
    	Result := V.DLValue.Month;
    vtDateTime:
    	Result := MonthOf(V.DTValue);
    vtString:
      if TryStrToDateTime(string(V.SValue), DT) then
        Result := MonthOf(DT)
      else
        Result := 0;
    vtArray:
    	Result := 0;
  else
  	Result := 0;
  end;
end;

{************* TDayOfFunction *************}

class function TDayOfFunction.GetName: string;
begin
  Result := 'day_of';
end;

class function TDayOfFunction.CheckParams(AParamsCount: integer): boolean;
begin
	Result := (AParamsCount = 1);
end;

class function TDayOfFunction.Evaluate(AParams: array of TVariableRecord): TVariableRecord;
var
	V: TVariableRecord;
  DT: TDateTime;
begin
	V := GetParam(0, AParams);
  case V.VarType of
    vtBoolean:
      if V.BValue then
      	Result := DayOf(Now)
      else
      	Result := 0;
    vtInteger:
    	Result := DayOf(V.IValue);
    vtFloat:
    	Result := DayOf(V.FValue);
    vtDateStrict:
    	Result := DayOf(V.DSValue);
    vtDateLoose:
    	Result := V.DLValue.Day;
    vtDateTime:
    	Result := DayOf(V.DTValue);
    vtString:
      if TryStrToDateTime(string(V.SValue), DT) then
        Result := DayOf(DT)
      else
        Result := 0;
    vtArray:
    	Result := 0;
  else
  	Result := 0;
  end;
end;


{************* TTemplateActions *************}

function TTemplateActions.Execute: string;
var
  I: integer;
begin
  Result := '';
  if Count > 0 then
    for I := 0 to Count - 1 do
      Result := Result + Items[I].Execute;
end;

{************* TTemplateAction *************}

constructor TTemplateAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create;
  FEngine := AEngine;
end;

class function TTemplateAction.IsComment(var ACommand: string): boolean;
begin
	if (ACommand[1] = '*') and (ACommand[Length(ACommand)] = '*') then
  	Result := true
  else begin
  	Result := false;
  	ACommand := SmartyTrim(ACommand);
  end;
end;

class function TTemplateAction.IsTag(const ATag: string; const ACommand: string;
	 AOnlyTag: boolean = false): boolean;
begin
	if AOnlyTag then
  	Result := CompareText(ATag, ACommand) = 0
  else
    Result := StartsWithSpace(ATag, ACommand) or (CompareText(ATag, ACommand) = 0);
end;

class function TTemplateAction.IsTagAndGetCommand(const ATag: string;
	var ACommand: string): boolean;
begin
	if CompareText(ATag, ACommand) = 0 then
  begin
  	Result := true;
    ACommand := '';
  end
  else if StartsWithSpace(ATag, ACommand) then
  begin
  	Result := true;
    Delete(ACommand, 1, Length(ATag) + 1);
  end
  else
  	Result := false;
end;

class function TTemplateAction.IsExitCommand(const ACommand: string;
	ABreakAction: TNestAction): boolean;
begin
	//IF Tags
  if IsTag('/if', ACommand, true) or
  	IsTag('else', ACommand, true) or IsTag('elseif', ACommand) or
    IsTag('elseifdef', ACommand) or IsTag('elseifndef', ACommand) or
    IsTag('elseifempty', ACommand) or IsTag('elseifnempty', ACommand) then
  begin
  	Result := true;
  	if ABreakAction <> naIf then
    	raise ESmartyException.CreateResFmt(@sInvalidIfCommand, [ACommand]);
  end
  //ForEach Tags
	else if IsTag('/foreach', ACommand, true) or IsTag('foreachelse', ACommand, true) then
  begin
  	Result := true;
  	if ABreakAction <> naForEach then
    	raise ESmartyException.CreateResFmt(@sInvalidForEachCommand, [ACommand]);
  end
  else
  	Result := false;
end;

class function TTemplateAction.ParseFunction(ACommand: string): TStringList;
var
  I: integer;
  InQuotes: boolean;
	Attribute: string;
  Ch: char;
begin
	Result := TStringList.Create;
  InQuotes := false;
	ACommand := SmartyTrim(ACommand);
  I := 1;
  Attribute := '';

  while I <= Length(ACommand) do
  begin
  	Ch := ACommand[I];
    Inc(I);

    if Ch = '"' then
    	if InQuotes then
      begin
      	if not (GetChar(ACommand, I) = '"') then
        	InQuotes := false
        else
        	Inc(I);
      end
      else
      	InQuotes := true
    else if IsSpace(Ch) and not InQuotes then
    begin
    	Attribute := SmartyTrim(Attribute);
      if Attribute <> '' then Result.Add(Attribute);
      Attribute := '';
    end
    else
    	Attribute := Attribute + Ch;
  end;

  Attribute := SmartyTrim(Attribute);
  if Attribute <> '' then Result.Add(Attribute);

  // First-char "=" signs should append to previous
  for I := Result.Count - 1 downto 1 do
    if Result[I][1] = '=' then
    begin
      Result[I - 1] := Result[I - 1] + Result[I];
      Result.Delete(I);
    end;

  // First-char quotes should append to previous
  for I := Result.Count - 1 downto 1 do
    if (Result[I][1] = '"') and (Pos('=', Result[I - 1]) > 0) then
    begin
      Result[I - 1] := Result[I - 1] + Result[I];
      Result.Delete(I);
    end;
end;

class procedure TTemplateAction.CheckFunction(ACommand: TStringList;
	AValid: array of string);
var
	I, J: integer;
  ACounts: array of byte;
  Name, Value: string;
  Found: boolean;
begin
	SetLength(ACounts, High(AValid) + 1);

	for I := 0 to ACommand.Count - 1 do
  begin
  	ExtractFunctionItem(ACommand, I, Name, Value);
    Found := false;
    for J := 0 to High(AValid) do
    	if CompareText(AValid[J], Name) = 0 then
      begin
        if ACounts[J] > 0 then
        	raise ESmartyException.CreateResFmt(@sDuplicateAttribute, [Name])
        else
        	ACounts[J] := 1;
        Found := true;
        Break;
      end;

    if not Found then
    	raise ESmartyException.CreateResFmt(@sInvalidAttribute, [Name]);
  end;
end;

class function TTemplateAction.GetAttributeValue(ACommand: TStringList;
	const AAtribute: string; const ADefault: string = ''): string;
var
	I: integer;
  Name, Value: string;
begin
	for I := 0 to ACommand.Count - 1 do
  begin
  	ExtractFunctionItem(ACommand, I, Name, Value);
    if CompareText(Name, AAtribute) = 0 then
		begin
      if Value = '' then
      	Exit(ADefault)
      else
      	Exit(Value);
    end;
  end;

  Result := ADefault;
end;

class procedure TTemplateAction.ExtractFunctionItem(ACommand: TStringList;
	Index: integer; var Name, Value: string);
var
	S: string;
  I: integer;
begin
	S := ACommand[Index];
  I := Pos('=', S);
  if I > 0 then
  begin
  	Name := Copy(S, 1, I - 1);
    Value := AnsiDequotedStr(Copy(S, I + 1, Length(S) - I), '"');
  end
  else begin
  	Name := S;
    Value := '';
  end;
end;

class procedure TTemplateAction.ParseVariable(AVariable: string; AVarList: TVarList);
var
	I, J: integer;
  S: string;
  Ch: char;
  InArrayIndex, SkipNextDot: boolean;
  Part: TVariablePart;
begin // FI:C101
  AVariable := AnsiUpperCase(AVariable);

  I := 1;
  S := '';
  InArrayIndex := false;
  SkipNextDot := false;

  while I <= Length(AVariable) do
  begin
    Ch := AVariable[I];
    Inc(I);

    if SkipNextDot then
    begin
      SkipNextDot := false;
      if (Ch = '.') then Continue;
    end;

    if Ch = '[' then
    begin
    	if InArrayIndex then
      	raise ESmartyException.CreateResFmt(@sInvalidArrayIndex, [AVariable]);
      InArrayIndex := true;
      if S <> '' then
      begin
      	Part := S;
      	S := '';
      	AVarList.Add(Part);
      end;
    end
    else if Ch = ']' then
    begin
    	if not InArrayIndex then
      	raise ESmartyException.CreateResFmt(@sUnpairBrackets, [AVariable]);
      InArrayIndex := false;
      SkipNextDot := true;
      if TryStrToInt(S, J) then
      begin
      	S := '';
      	Part := J;
        AVarList.Add(Part);
      end
      else
      	raise ESmartyException.CreateResFmt(@sInvalidCharsInArrayIndex, [AVariable]);
    end
    else if Ch = '.' then
    begin
      Part := S;
      S := '';
      AVarList.Add(Part);
    end
    else if CharInSet(Ch, ['A'..'Z', 'a'..'z', '_', '0'..'9']) then
    	S := S + Ch
    else
    	raise ESmartyException.CreateResFmt(@sInvalidVarChars, [Ch, AVariable]);
  end;

  if InArrayIndex then
  	raise ESmartyException.CreateResFmt(@sUnclosedBrackets, [AVariable]);
  if S <> '' then
  begin
  	Part := S;
    AVarList.Add(Part);
  end;
end;

class procedure TTemplateAction.GetVariableProperties(AEngine: TSmartyEngine;
	const AVariable: string; var Namespace: TNamespaceProvider; var Index: integer;
  var VarName: string; var AVarList: TVarList);
var
  NamespaceIndex: integer;
  NamespaceName: string;
begin
  ParseVariable(AVariable, AVarList);
  if (AVarList.Count > 0) and (AVarList[0].PartType = vptValue) then
  begin
    NamespaceName := AVarList[0];
    AVarList.DeleteElement(0);
    NamespaceIndex := AEngine.FNamespaces.IndexOf(NamespaceName);
    if NamespaceIndex >= 0 then
    begin
      Namespace := TNamespaceProvider(AEngine.FNamespaces.Objects[NamespaceIndex]);
      if AVarList.Count > 0 then
      begin
      	if Namespace.IsIndexSupported then
        begin
        	if (AVarList[0].PartType = vptIndex) then
          begin
          	Index := AVarList[0];
          	AVarList.DeleteElement(0);
          end
          else
          	raise ESmartyException.CreateResFmt(@sNamespaceIndexMiss, [AVariable]);
      	end
        else
        	Index := -1;

        if (AVarList.Count > 0) and (AVarList[0].PartType = vptValue) then
        begin
        	VarName := AVarList[0];
          AVarList.DeleteElement(0);
        end
        else
        	raise ESmartyException.CreateResFmt(@sNamespaceVarMiss, [AVariable]);
      end
      else begin
      //detach variables
        Namespace := nil;
        Index := -1;
        VarName := NamespaceName;
      end;
    end
    else begin
    	Namespace := nil;
      Index := -1;
      VarName := NamespaceName;
    end;
  end
  else
    raise ESmartyException.CreateResFmt(@sInvalidVariable, [AVariable]);
end;

class function TTemplateAction.IsAction(AEngine: TSmartyEngine;
	ACommand: string; var AAction: TTemplateAction): boolean; // FI:O801
begin
	Result := false;
  AAction := nil;
end;

{************* TRawOutputAction *************}

constructor TRawOutputAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatRawOutput;
end;

constructor TRawOutputAction.CreateOutput(AEngine: TSmartyEngine; const AOutput: string);
begin
	inherited Create(AEngine);
  FOutput := AOutput;
end;

function TRawOutputAction.Execute: string;
begin
  Result := FOutput;
end;

class function TRawOutputAction.IsAction(AEngine: TSmartyEngine;
	ACommand: string; var AAction: TTemplateAction): boolean;
begin
	AAction := nil;
  // { symbol
  if CompareText(ACommand, 'ldelim') = 0 then AAction := TRawOutputAction.CreateOutput(AEngine, '{')
  // } symbol
  else if CompareText(ACommand, 'rdelim') = 0 then AAction := TRawOutputAction.CreateOutput(AEngine, '}');

  Result := Assigned(AAction);
end;

{************* TModifierAction *************}

constructor TModifierAction.Create;
begin
	inherited Create;
  FModifier := nil;
  FParams := nil;
end;

destructor TModifierAction.Destroy;
begin
	if Assigned(FParams) then FParams.Free;
	inherited Destroy;
end;

{************* TVariableOutputAction *************}

constructor TVariableOutputAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FNamespace := nil;
  FVarDetails := TVarList.Create;
  FModifiers := TObjectList<TModifierAction>.Create(true);
  FActionType := tatVariableOutput;
end;

destructor TVariableOutputAction.Destroy;
begin
	FVarDetails.Finalize;
  FModifiers.Free;
	inherited Destroy;
end;

function TVariableOutputAction.Execute: string;
var
	I: integer;
  VarRec: TVariableRecord;
  Temp: TVariableRecord;
  NeedFinalize: boolean;
begin
  VarRec := FEngine.GetVariable(FNamespace, FIndex, FVarName, FVarDetails, NeedFinalize);
  try
    if FModifiers.Count > 0 then
    begin
      Temp := VarRec.Clone;
      try
        for I := 0 to FModifiers.Count - 1 do
          FModifiers[I].FModifier.ModifyVariable(Temp, FModifiers[I].FParams);
        if FEngine.AutoHTMLEncode then
        	Result := HTMLEncode(Temp.ToString)
        else
        	Result := Temp.ToString;
      finally
        Temp.Finalize;
      end;
    end
    else
      if FEngine.AutoHTMLEncode then
      	Result := HTMLEncode(VarRec.ToString)
      else
        Result := VarRec.ToString
  finally
    if NeedFinalize then VarRec.Finalize;
  end;
end;

procedure TVariableOutputAction.SetVariable(AEngine: TSmartyEngine;
	const AVariable: string);
begin
	GetVariableProperties(AEngine, AVariable, FNamespace, FIndex, FVarName, FVarDetails);
end;

class function TVariableOutputAction.IsAction(AEngine: TSmartyEngine; // FI:C103
	ACommand: string; var AAction: TTemplateAction): boolean;
var
	I, J: integer;
  VarAction: TVariableOutputAction;
  Ch: Char;
  Modifier, Variable, Param: string;
  Params: TStringList;
  InQuote: boolean;
  MAction: TModifierAction;
begin // FI:C101
	if (ACommand[1] = '$') then
  begin
  	Result := true;
  	VarAction := TVariableOutputAction.Create(AEngine);
    AAction := VarAction;

    I := 2;
    Variable := '';

    Ch := GetChar(ACommand, I);
    while CharInSet(Ch, ['A'..'Z','a'..'z','_','.', '[', ']', '0'..'9']) do
    begin
      Variable := Variable + Ch;
      Inc(I);
      Ch := GetChar(ACommand, I);
    end;

    if Ch = #0 then
    begin
    	VarAction.SetVariable(AEngine, Variable);
    	Exit;
    end;

    while Ch <> #0 do
    begin
      if IsSpace(Ch) then
      begin
        Inc(I);
        while IsSpace(GetChar(ACommand, I)) do Inc(I);
        Ch := GetChar(ACommand, I);
      end;

      if Ch = #0 then
    	begin
    		VarAction.SetVariable(AEngine, Variable);
    		Exit;
    	end;

      if Ch = '|' then
      begin
        Inc(I);
        Modifier := '';
        Ch := GetChar(ACommand, I);

        if IsSpace(Ch) then
        begin
          Inc(I);
          while IsSpace(GetChar(ACommand, I)) do Inc(I);
          Ch := GetChar(ACommand, I);
        end;

        while not CharInSet(Ch, [#0..' ','{','}','|',':']) do
        begin
          Modifier := Modifier + Ch;
          Inc(I);
          Ch := GetChar(ACommand, I);
        end;

        if Ch = ':' then
        begin
          Params := TStringList.Create;
          InQuote := false;
          Param := '';
          Inc(I);

          while true do
          begin
            Ch := GetChar(ACommand, I);
            Inc(I);

            if (Ch = '"') then
            begin
              if InQuote then
                if GetChar(ACommand, I) = '"' then
                begin
                  Param := Param + '"';
                  Inc(I);
                end
                else
                  InQuote := false
              else
                InQuote := true;
            end
            else if (Ch = ':') and not InQuote then
            begin
              Params.Add(Param);
              Param := '';
            end
            else if (Ch = #0) or (not InQuote and (Ch = '|')) then
              Break
            else
              Param := Param + Ch;
          end;

          if Param <> '' then Params.Add(Param);
        end
        else
          Params := nil;

        MAction := TModifierAction.Create;
        MAction.FParams := Params;
        VarAction.FModifiers.Add(MAction);

        J := SmartyProvider.FModifiers.IndexOf(Modifier);
        if J >= 0 then
        begin
          MAction.FModifier := SmartyProvider.FModifiers.GetModifier(J);
          if not MAction.FModifier.CheckInputParams(Params) then
          begin
          	FreeAndNil(AAction);
          	raise ESmartyException.CreateResFmt(@sInvalidModifierParams, [Modifier]);
          end;
        end
        else begin
        	FreeAndNil(AAction);
          raise ESmartyException.CreateResFmt(@sInvalidModifier, [Modifier]);
        end;
      end
      else begin
      	FreeAndNil(AAction);
        raise ESmartyException.CreateResFmt(@sInvalidTemplateChar, [Ch, ACommand]);
      end;
    end;

		VarAction.SetVariable(AEngine, Variable);
  end
  else begin
  	Result := false;
    AAction := nil;
  end;
end;

{************* TFuncOutputAction *************}

constructor TFuncOutputAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FOperation := nil;
  FModifiers := TObjectList<TModifierAction>.Create(true);
  FActionType := tatFuncOutput;
end;

destructor TFuncOutputAction.Destroy;
begin
	FOperation.Free;
  FModifiers.Free;
	inherited Destroy;
end;

function TFuncOutputAction.Execute: string;
var
	I: integer;
  VarRec: TVariableRecord;
  Temp: TVariableRecord;
  NeedFinalize: boolean;
begin
  VarRec := FOperation.Evaluate(FEngine, NeedFinalize);
  try
    if FModifiers.Count > 0 then
    begin
      Temp := VarRec.Clone;
      try
        for I := 0 to FModifiers.Count - 1 do
          FModifiers[I].FModifier.ModifyVariable(Temp, FModifiers[I].FParams);
        if FEngine.AutoHTMLEncode then
        	Result := HTMLEncode(Temp.ToString)
        else
        	Result := Temp.ToString;
      finally
        Temp.Finalize;
      end;
    end
    else
      if FEngine.AutoHTMLEncode then
      	Result := HTMLEncode(VarRec.ToString)
      else
      	Result := VarRec.ToString;
  finally
    if NeedFinalize then VarRec.Finalize;
  end;
end;

class function TFuncOutputAction.IsAction(AEngine: TSmartyEngine; // FI:C103
	ACommand: string; var AAction: TTemplateAction): boolean;
var
	I, J: integer;
  FuncAction: TFuncOutputAction;
  Ch: Char;
  FuncParams, Modifiers, Modifier, Param: string;
  FuncClass: TSmartyFunctionClass;
  Params: TStringList;
  InQuote: boolean;
  MAction: TModifierAction;
begin // FI:C101
	if AEngine.IsFunction(ACommand, FuncClass, FuncParams, Modifiers) then
  begin
  	Result := true;
  	FuncAction := TFuncOutputAction.Create(AEngine);
    FuncAction.FOperation := TOperation.Parse(AEngine, FuncClass.GetName + '(' + FuncParams + ')');
    AAction := FuncAction;

    I := 1;

    Ch := GetChar(Modifiers, I);
    while Ch <> #0 do
    begin
      if IsSpace(Ch) then
      begin
        Inc(I);
        while IsSpace(GetChar(Modifiers, I)) do Inc(I);
        Ch := GetChar(Modifiers, I);
      end;

      if Ch = '|' then
      begin
        Inc(I);
        Modifier := '';
        Ch := GetChar(Modifiers, I);

        if IsSpace(Ch) then
        begin
          Inc(I);
          while IsSpace(GetChar(Modifiers, I)) do Inc(I);
          Ch := GetChar(Modifiers, I);
        end;

        while not CharInSet(Ch, [#0..' ','{','}','|',':']) do
        begin
          Modifier := Modifier + Ch;
          Inc(I);
          Ch := GetChar(Modifiers, I);
        end;

        if Ch = ':' then
        begin
          Params := TStringList.Create;
          InQuote := false;
          Param := '';
          Inc(I);

          while true do
          begin
            Ch := GetChar(Modifiers, I);
            Inc(I);

            if (Ch = '"') then
            begin
              if InQuote then
                if GetChar(Modifiers, I) = '"' then
                begin
                  Param := Param + '"';
                  Inc(I);
                end
                else
                  InQuote := false
              else
                InQuote := true;
            end
            else if (Ch = ':') and not InQuote then
            begin
              Params.Add(Param);
              Param := '';
            end
            else if (Ch = #0) or (not InQuote and (Ch = '|')) then
              Break
            else
              Param := Param + Ch;
          end;

          if Param <> '' then Params.Add(Param);
        end
        else
          Params := nil;

        MAction := TModifierAction.Create;
        MAction.FParams := Params;
        FuncAction.FModifiers.Add(MAction);

        J := SmartyProvider.FModifiers.IndexOf(Modifier);
        if J >= 0 then
        begin
          MAction.FModifier := SmartyProvider.FModifiers.GetModifier(J);
          if not MAction.FModifier.CheckInputParams(Params) then
          begin
          	FreeAndNil(AAction);
          	raise ESmartyException.CreateResFmt(@sInvalidModifierParams, [Modifier]);
          end;
        end
        else begin
        	FreeAndNil(AAction);
          raise ESmartyException.CreateResFmt(@sInvalidModifier, [Modifier]);
        end;
      end
      else begin
      	FreeAndNil(AAction);
        raise ESmartyException.CreateResFmt(@sInvalidTemplateChar, [Ch, Modifiers]);
      end;
    end;
  end
  else begin
  	Result := false;
    AAction := nil;
  end;
end;


{************* TOperation *************}

type
	TExpressionItem = class (TObject)
  	constructor Create; virtual;
    destructor Destroy; override;
  	class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer; var Item: TExpressionItem): boolean; virtual;   //only skip spaces and return false
    function CreateLink(AEngine: TSmartyEngine): TOperation; virtual;
    function GetLink: TOperation; virtual;
    procedure SetNilLink; virtual;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; virtual;
  {$ENDIF}
  end;

  TVariableItem = class (TExpressionItem)  //$person.year
    VarName: string;
    Link: TOpVariable;
  	constructor Create; override;
    destructor Destroy; override;
    class function IsItem(const S: string; const Index: integer): boolean;
    procedure ScanStr(const S: string; var Index: integer);
  	class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer;	var Item: TExpressionItem): boolean; override;
    function CreateLink(AEngine: TSmartyEngine): TOperation; override;
    function GetLink: TOperation; override;
    procedure SetNilLink; override;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; override;
  {$ENDIF}
  end;

  TIdentifierItem = class (TExpressionItem) //true, false, null, shl, shr, is_null (function name)
		Name: string;
    Link: TOpFunction;
  	constructor Create; override;
    destructor Destroy; override;
    class function IsItem(const S: string; const Index: integer): boolean;
    procedure ScanStr(const S: string; var Index: integer);
  	class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer;	var Item: TExpressionItem): boolean; override;
    function IsConstItem(var Item: TExpressionItem): boolean;
    function IsOperatorItem(var Item: TExpressionItem): boolean;
    function CreateLink(AEngine: TSmartyEngine): TOperation; override;
    function GetLink: TOperation; override;
    procedure SetNilLink; override;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; override;
  {$ENDIF}
  end;

  TConstItem = class (TExpressionItem)
  	NeedFinalize: boolean;
  	Value: TVariableRecord;
    Link: TOpConst;
  	constructor Create; override;
    destructor Destroy; override;
    class function IsNumberItem(const S: string; const Index: integer): boolean;
    class function IsStringItem(const S: string; const Index: integer): boolean;
    class function IsDateTimeItem(const S: string; const Index: integer): boolean;
    class function IsDateLooseItem(const S: string; const Index: integer): boolean;
    procedure ScanNumberItem(const S: string; var Index: integer);
    procedure ScanStringItem(const S: string; var Index: integer; AParseEsapces: boolean);
    procedure ScanDateItem(const S: string; Loose: boolean; var Index: integer);
    class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer;	var Item: TExpressionItem): boolean; override;
    function CreateLink(AEngine: TSmartyEngine): TOperation; override;
    function GetLink: TOperation; override;
    procedure SetNilLink; override;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; override;
  {$ENDIF}
  end;

  TOperatorItem = class (TExpressionItem)
  	Op: TOperator;
    Link: TOpOperator;
  	constructor Create; override;
    destructor Destroy; override;
    function GetPrecedence: byte;
    class function IsItem(const S: string; const Index: integer): boolean;
    procedure ScanStr(const S: string; var Index: integer);
  	class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer;	var Item: TExpressionItem): boolean; override;
    function GetLink: TOperation; override;
    procedure SetNilLink; override;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; override;
  {$ENDIF}
  end;

  TParenthesisType = (ptOpen {(}, ptClose {)}, ptComma {,});

  TParenthesisItem = class (TExpressionItem)
    ParenthesisType: TParenthesisType;
  	constructor Create; override;
    destructor Destroy; override;
    class function IsItem(const S: string; const Index: integer): boolean;
    procedure ScanStr(const S: string; var Index: integer);
  	class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer;	var Item: TExpressionItem): boolean; override;
		function GetLink: TOperation; override;
    procedure SetNilLink; override;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; override;
  {$ENDIF}
  end;

  TOpItem = class (TExpressionItem)
    Link: TOperation;
  	constructor Create; override;
    destructor Destroy; override;
  	class function ParseItem(AEngine: TSmartyEngine; const S: string;
      var Index: integer;	var Item: TExpressionItem): boolean; override;
		function GetLink: TOperation; override;
    procedure SetNilLink; override;
  {$IFDEF SMARTYDEBUG}
    function AsString: string; override;
  {$ENDIF}
  end;

{************* TExpressionItem *************}

constructor TExpressionItem.Create;
begin
	inherited Create;
end;

destructor TExpressionItem.Destroy;
begin
  inherited Destroy;
end;

class function TExpressionItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
var
	Ch: char;
begin
	Ch := GetChar(S, Index);
	while IsSpace(Ch) and not (Ch = #0) do
  begin
  	Inc(Index);
    Ch := GetChar(S, Index);
  end;
	Result := false;
end;

function TExpressionItem.CreateLink(AEngine: TSmartyEngine): TOperation;
begin
	Result := nil;
end;

function TExpressionItem.GetLink: TOperation;
begin
  Result := nil;
end;

procedure TExpressionItem.SetNilLink;
begin
end;

{$IFDEF SMARTYDEBUG}
function TExpressionItem.AsString: string;
begin
	Result := '';
end;
{$ENDIF}

{************* TVariableItem *************}

constructor TVariableItem.Create;
begin
	inherited Create;
  Link := nil;
end;

destructor TVariableItem.Destroy;
begin
	if Assigned(Link) then Link.Free;
  inherited Destroy;
end;

class function TVariableItem.IsItem(const S: string; const Index: integer): boolean;
begin
	Result := GetChar(S, Index) = '$';
end;

procedure TVariableItem.ScanStr(const S: string; var Index: integer);
var
	Ch: char;
begin
	Inc(Index);
  Ch := GetChar(S, Index);
  VarName := '';
	while CharInSet(Ch, ['A'..'Z','a'..'z','_','.', '[', ']', '0'..'9']) do
  begin
    VarName := VarName + Ch;
    Inc(Index);
    Ch := GetChar(S, Index);
  end;
end;

class function TVariableItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
begin
	inherited;

  Result := IsItem(S, Index);
  if Result then
  begin
  	Item := TVariableItem.Create;
    TVariableItem(Item).ScanStr(S, Index);
  end;
end;

function TVariableItem.CreateLink(AEngine: TSmartyEngine): TOperation;
begin
	Link := TOpVariable.Create;
  Result := Link;
	TTemplateAction.GetVariableProperties(AEngine, VarName, Link.FNamespace,
  	Link.FIndex, Link.FVarName, Link.FVarDetails);
end;

function TVariableItem.GetLink: TOperation;
begin
  Result := Link;
end;

procedure TVariableItem.SetNilLink;
begin
	Link := nil;
end;

{$IFDEF SMARTYDEBUG}
function TVariableItem.AsString: string;
begin
	Result := ' VAR%' + VarName + '% ';
end;
{$ENDIF}

{************* TIdentifierItem *************}

constructor TIdentifierItem.Create;
begin
	inherited Create;
  Link := nil;
end;

destructor TIdentifierItem.Destroy;
begin
	if Assigned(Link) then Link.Free;
  inherited Destroy;
end;

class function TIdentifierItem.IsItem(const S: string; const Index: integer): boolean;
begin
	Result := CharInSet(GetChar(S, Index), ['A'..'Z','a'..'z','_']);
end;

procedure TIdentifierItem.ScanStr(const S: string; var Index: integer);
var
	Ch: char;
begin
  Name := GetChar(S, Index);
	Inc(Index);
  Ch := GetChar(S, Index);
	while CharInSet(Ch, ['A'..'Z','a'..'z','_', '0'..'9']) do
  begin
    Name := Name + Ch;
    Inc(Index);
    Ch := GetChar(S, Index);
  end;
end;

class function TIdentifierItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
begin
	inherited;

  Result := IsItem(S, Index);
  if Result then
  begin
  	Item := TIdentifierItem.Create;
    TIdentifierItem(Item).ScanStr(S, Index);
  end;
end;

function TIdentifierItem.IsConstItem(var Item: TExpressionItem): boolean;

	procedure CreateConstItem(Value: TVariableRecord);
  begin
  	Item := TConstItem.Create;
    TConstItem(Item).Value := Value;
  end;

begin
	Result := true;
	if CompareText('true', Name) = 0 then CreateConstItem(true)
  else if CompareText('false', Name) = 0 then CreateConstItem(false)
  else if CompareText('null', Name) = 0 then CreateConstItem(TVariableRecord.Null)
  else Result := false;
end;

function TIdentifierItem.IsOperatorItem(var Item: TExpressionItem): boolean;

	procedure CreateOperatorItem(Value: TOperator);
  begin
  	Item := TOperatorItem.Create;
    TOperatorItem(Item).Op := Value;
  end;

begin
	Result := true;
	if CompareText('eq', Name) = 0 then CreateOperatorItem(opEq)
  else if CompareText('ne', Name) = 0 then CreateOperatorItem(opNeq)
  else if CompareText('neq', Name) = 0 then CreateOperatorItem(opNeq)
  else if CompareText('gt', Name) = 0 then CreateOperatorItem(opGt)
  else if CompareText('lt', Name) = 0 then CreateOperatorItem(opLt)
  else if CompareText('gte', Name) = 0 then CreateOperatorItem(opGte)
  else if CompareText('ge', Name) = 0 then CreateOperatorItem(opGte)
  else if CompareText('lte', Name) = 0 then CreateOperatorItem(opLte)
  else if CompareText('le', Name) = 0 then CreateOperatorItem(opLte)
  else if CompareText('seq', Name) = 0 then CreateOperatorItem(opSEq)
  else if CompareText('mod', Name) = 0 then CreateOperatorItem(opMod)
  else if CompareText('div', Name) = 0 then CreateOperatorItem(opDiv)
  else if CompareText('shl', Name) = 0 then CreateOperatorItem(opShl)
  else if CompareText('shr', Name) = 0 then CreateOperatorItem(opShr)
  else if CompareText('not', Name) = 0 then CreateOperatorItem(opLogicalNot)
  else if CompareText('and', Name) = 0 then CreateOperatorItem(opLogicalAnd)
  else if CompareText('or', Name) = 0 then CreateOperatorItem(opLogicalOr)
  else if CompareText('bitand', Name) = 0 then CreateOperatorItem(opBitwiseAnd)
  else if CompareText('bitor', Name) = 0 then CreateOperatorItem(opBitwiseOr)
  else if CompareText('xor', Name) = 0 then CreateOperatorItem(opBitwiseXor)
  else Result := false;
end;

function TIdentifierItem.CreateLink(AEngine: TSmartyEngine): TOperation;
begin
	Link := TOpFunction.Create;
  Result := Link;
	Link.FFuncClass := AEngine.GetFunction(Name);
  if not Assigned(Link.FFuncClass) then
  	raise ESmartyException.CreateResFmt(@sInvalidFunction, [Name]);
end;

function TIdentifierItem.GetLink: TOperation;
begin
  Result := Link;
end;

procedure TIdentifierItem.SetNilLink;
begin
	Link := nil;
end;

{$IFDEF SMARTYDEBUG}
function TIdentifierItem.AsString: string;
begin
	Result := ' IDENT%' + Name + '% ';
end;
{$ENDIF}


{************* TConstItem *************}

constructor TConstItem.Create;
begin
	inherited Create;
  Link := nil;
  NeedFinalize := true;
end;

destructor TConstItem.Destroy;
begin
	if Assigned(Link) then
  	Link.Free
  else
  	if NeedFinalize then Value.Finalize;
  inherited Destroy;
end;

class function TConstItem.IsNumberItem(const S: string; const Index: integer): boolean;
var
	Ch: char;
begin
	Ch := GetChar(S, Index);
	Result := CharInSet(Ch, ['0'..'9','.']) or
  	(((Ch = '+') or (Ch = '-')) and CharInSet(GetChar(S, Index + 1), ['0'..'9','.']));
end;

class function TConstItem.IsStringItem(const S: string; const Index: integer): boolean;
begin
	Result := GetChar(S, Index) = '"';
end;

class function TConstItem.IsDateTimeItem(const S: string; const Index: integer): boolean;
begin
	Result := (GetChar(S, Index) = 'D') and (GetChar(S, Index + 1) = '"');
end;

class function TConstItem.IsDateLooseItem(const S: string; const Index: integer): boolean;
begin
	Result := (GetChar(S, Index) = 'L') and (GetChar(S, Index + 1) = '"');
end;

procedure TConstItem.ScanNumberItem(const S: string; var Index: integer);
var
	Str: string;
  IntConst: boolean;
  Ch: char;
	I, J: integer;
  D: double;
begin // FI:C101
	IntConst := true;
	Str := GetChar(S, Index);
	Inc(Index);
  Ch := GetChar(S, Index);
	while CharInSet(Ch, ['0'..'9']) do
  begin
    Str := Str + Ch;
    Inc(Index);
    Ch := GetChar(S, Index);
  end;

  if Ch = '.' then
  begin
  	IntConst := false;
  	Str := Str + Ch;
		Inc(Index);
  	Ch := GetChar(S, Index);

    while CharInSet(Ch, ['0'..'9']) do
    begin
      Str := Str + Ch;
      Inc(Index);
      Ch := GetChar(S, Index);
    end;
  end;

  if CharInSet(Ch, ['e', 'E']) then
  begin
  	IntConst := false;
  	Str := Str + Ch;
		Inc(Index);
  	Ch := GetChar(S, Index);

    if CharInSet(Ch, ['-', '+']) then
    begin
  		Str := Str + Ch;
			Inc(Index);
  		Ch := GetChar(S, Index);
    end;

    while CharInSet(Ch, ['0'..'9']) do
    begin
      Str := Str + Ch;
      Inc(Index);
      Ch := GetChar(S, Index);
    end;
  end;

  if IntConst then
  begin
  	Val(Str, I, J);
    if J = 0 then
    	Value := I
    else
    	raise ESmartyException.CreateResFmt(@sInvalidIntegerConst, [Str]);
  end
  else begin
  	Val(Str, D, J);
    if J = 0 then
    	Value := D
    else
    	raise ESmartyException.CreateResFmt(@sInvalidFloatConst, [Str]);
  end;
end;

procedure TConstItem.ScanStringItem(const S: string; var Index: integer;
  AParseEsapces: boolean);
var
	Str: string;
  Ch: char;
begin
	Inc(Index);
  Ch := GetChar(S, Index);
  Str := '';

	while Ch <> #0 do
  begin
  	if Ch = '"' then
    begin
    	if GetChar(S, Index + 1) = '"' then
      begin
      	Str := Str + '"';
        Inc(Index);
      end
      else begin
      	Inc(Index);
      	Break;
      end;
    end
    else
    	Str := Str + Ch;

    Inc(Index);
    Ch := GetChar(S, Index);
  end;

  if AParseEsapces then
    Value := ParseEscapes(Str)
  else
    Value := Str;
end;

procedure TConstItem.ScanDateItem(const S: string; Loose: boolean; var Index: integer);
var
	I: integer;
  Str: string;
begin
	Inc(Index, 2);
  I := PosEx('"', S, Index);
  if I > 0 then
  begin
  	Str := Copy(S, Index, I - Index + 1);
    Index := I + 1;

    try
      if Loose then
        Value := DateLooseFromString(Str)
      else
        Value := DateTimeFromString(Str);
    except
    	raise ESmartyException.CreateResFmt(@sInvalidDateConst, [Str]);
    end;
  end;
end;

class function TConstItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
begin
	inherited;

  Result := true;
  if IsNumberItem(S, Index) then
  begin
  	Item := TConstItem.Create;
    TConstItem(Item).ScanNumberItem(S, Index);
  end
	else if IsStringItem(S, Index) then
  begin
  	Item := TConstItem.Create;
    TConstItem(Item).ScanStringItem(S, Index, AEngine.AllowEspacesInStrings);
  end
	else if IsDateTimeItem(S, Index) then
  begin
  	Item := TConstItem.Create;
    TConstItem(Item).ScanDateItem(S, false, Index);
  end
	else if IsDateLooseItem(S, Index) then
  begin
  	Item := TConstItem.Create;
    TConstItem(Item).ScanDateItem(S, true, Index);
  end
	else
  	Result := false;
end;

function TConstItem.CreateLink(AEngine: TSmartyEngine): TOperation;
begin
	Link := TOpConst.Create;
  Result := Link;
	Link.FValue := Value;
end;

function TConstItem.GetLink: TOperation;
begin
  Result := Link;
end;

procedure TConstItem.SetNilLink;
begin
	Link := nil;
  NeedFinalize := false;
end;

{$IFDEF SMARTYDEBUG}
function TConstItem.AsString: string;
begin
	Result := ' CONST%' + Value.ToString + '% ';
end;
{$ENDIF}

{************* TOperatorItem *************}

constructor TOperatorItem.Create;
begin
	inherited Create;
  Link := nil;
end;

destructor TOperatorItem.Destroy;
begin
	if Assigned(Link) then Link.Free;
  inherited Destroy;
end;

function TOperatorItem.GetPrecedence: byte;
begin
	Result := OperatorPrecedence[Op];
end;

class function TOperatorItem.IsItem(const S: string;
	const Index: integer): boolean;
var
	Ch: char;
begin
	Ch := GetChar(S, Index);
	Result := CharInSet(Ch, ['!', '<', '>', '+', '-', '*', '/', '\', '%',
  	'=', '&', '|', '~', '^']);
end;

procedure TOperatorItem.ScanStr(const S: string; var Index: integer);
var
	Ch: char;
begin // FI:C101
	Ch := GetChar(S, Index);
  Inc(Index);
	case Ch of
  	'!' :
      begin
        case GetChar(S, Index) of
          '=':
          	begin Op := opNeq; Inc(Index); end;
        else
          Op := opLogicalNot;
        end;
      end;

    '>' :
    	begin
      	case GetChar(S, Index) of
        	'=':
          	begin Op := opGte; Inc(Index); end;
          '>':
          	begin Op := opShr; Inc(Index); end;
        else
          Op := opGt;
        end;
      end;
    '<' :
    	begin
      	case GetChar(S, Index) of
        	'>':
          	begin Op := opNeq; Inc(Index); end;
        	'=':
          	begin Op := opLte; Inc(Index); end;
          '<':
          	begin Op := opShl; Inc(Index); end;
        else
          Op := opLt;
        end;
      end;

    '+' :
    	Op := opAdd;
    '-' :
    	Op := opSub;
    '*' :
    	Op := opMply;
    '/' :
    	Op := opDivide;
    '\' :
    	Op := opDiv;
    '%' :
    	Op := opMod;
    '=' :
    	if GetChar(S, Index) = '=' then
      begin
      	Op := opSEq; Inc(Index);
      end
      else
      	Op := opEq;

    '&' :
    	if GetChar(S, Index) = '&' then
      begin
      	Op := opLogicalAnd; Inc(Index);
      end
      else
    	Op := opBitwiseAnd;
    '|' :
    	if GetChar(S, Index) = '|' then
      begin
      	Op := opLogicalOr; Inc(Index);
      end
      else
      	Op := opBitwiseOr;
    '~' :
    	Op := opBitwiseNot;
    '^' :
    	Op := opBitwiseXor;
  end;
end;

class function TOperatorItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
begin
	inherited;

  Result := IsItem(S, Index);
  if Result then
  begin
  	Item := TOperatorItem.Create;
    TOperatorItem(Item).ScanStr(S, Index);
  end;
end;

function TOperatorItem.GetLink: TOperation;
begin
  Result := Link;
end;

procedure TOperatorItem.SetNilLink;
begin
	Link := nil;
end;

{$IFDEF SMARTYDEBUG}
function TOperatorItem.AsString: string;
begin
	case Op of
    opEq:
    	Result := ' = ';
    opNeq:
    	Result := ' != ';
    opGt:
    	Result := ' > ';
    opLt:
    	Result := ' < ';
    opGte:
    	Result := ' >= ';
    opLte:
    	Result := ' <= ';
    opSEq:
    	Result := ' == ';
    opAdd:
    	Result := ' + ';
    opSub:
    	Result := ' - ';
    opMply:
    	Result := ' * ';
    opDivide:
    	Result := ' / ';
    opMod:
    	Result := ' % ';
    opDiv:
    	Result := ' \ ';
    opShl:
    	Result := ' << ';
    opShr:
    	Result := ' >> ';
    opLogicalNot:
    	Result := ' ! ';
    opLogicalAnd:
    	Result := ' && ';
    opLogicalOr:
    	Result := ' || ';
    opBitwiseNot:
    	Result := ' ~ ';
    opBitwiseAnd:
    	Result := ' & ';
    opBitwiseOr:
    	Result := ' | ';
    opBitwiseXor:
    	Result := ' ^ ';
  else
  	Result := ' ILLEGAL ';
  end;
end;
{$ENDIF}

{************* TParenthesisItem *************}

constructor TParenthesisItem.Create;
begin
	inherited Create;
end;

destructor TParenthesisItem.Destroy;
begin
  inherited Destroy;
end;

class function TParenthesisItem.IsItem(const S: string; const Index: integer): boolean;
var
	Ch: char;
begin
	Ch := GetChar(S, Index);
	Result := (Ch = '(') or (Ch = ')') or (Ch = ',');
end;

procedure TParenthesisItem.ScanStr(const S: string; var Index: integer);
var
	Ch: char;
begin
	Ch := GetChar(S, Index);
	if Ch = '(' then ParenthesisType := ptOpen
  else if Ch = ')' then ParenthesisType := ptClose
  else if Ch = ',' then ParenthesisType := ptComma;
  Inc(Index);
end;

class function TParenthesisItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
begin
	inherited;

  Result := IsItem(S, Index);
  if Result then
  begin
  	Item := TParenthesisItem.Create;
    TParenthesisItem(Item).ScanStr(S, Index);
  end;
end;

function TParenthesisItem.GetLink: TOperation;
begin
  Result := nil;
end;

procedure TParenthesisItem.SetNilLink;
begin
end;

{$IFDEF SMARTYDEBUG}
function TParenthesisItem.AsString: string;
begin
	case ParenthesisType of
  	ptOpen:
    	Result := ' ( ';
    ptComma:
    	Result := ' , ';
    ptClose:
    	Result := ' ) ';
  else
  	Result := ' ILLEGAL ';
  end;
end;
{$ENDIF}

{************* TOpItem *************}

constructor TOpItem.Create;
begin
	inherited Create;
  Link := nil;
end;

destructor TOpItem.Destroy;
begin
	if Assigned(Link) then Link.Free;
  inherited Destroy;
end;

class function TOpItem.ParseItem(AEngine: TSmartyEngine; const S: string;
  var Index: integer; var Item: TExpressionItem): boolean;
begin
	Result := false;
end;

function TOpItem.GetLink: TOperation;
begin
  Result := Link;
end;

procedure TOpItem.SetNilLink;
begin
	Link := nil;
end;

{$IFDEF SMARTYDEBUG}
function TOpItem.AsString: string;
begin
	Result := ' %OPITEM% ';
end;
{$ENDIF}

{************* TOperation *************}

constructor TOperation.Create;
begin
	inherited Create;
end;

class function TOperation.Parse(AEngine: TSmartyEngine; S: string): TOperation;

  {$IFDEF SMARTYDEBUG}
  procedure ShowExpr(AExpr: TObjectList<TExpressionItem>);
  var
  	I: integer;
    Str: string;
  begin
    Str := '';
    for I := 0 to AExpr.Count - 1 do
    	Str := Str + AExpr[I].AsString;
    OutputDebugString(PChar(Str));
  end;
  {$ENDIF}

  procedure TransferTo(AFrom, ATo: TObjectList<TExpressionItem>; AIndex: integer);
  begin
  	ATo.Add(AFrom[AIndex]);
    AFrom.OwnsObjects := false;
    AFrom.Delete(AIndex);
    AFrom.OwnsObjects := true;
  end;

  function AnalyzeParseData(Data: TObjectList<TExpressionItem>): TOperation; // FI:C103
  var
  	I, J, Stack: integer;
    EItem, LItem, RItem: TExpressionItem;
    IdItem: TIdentifierItem;
    PnItem: TParenthesisItem;
    OpItem: TOperatorItem;
    OItem: TOpItem;
    FuncLink: TOpFunction;
    LOp, ROp: TOperation;
    Params: TObjectList<TExpressionItem>;
  begin
  	{$IFDEF SMARTYDEBUG} ShowExpr(Data); {$ENDIF}

  	I := 0;
    while I < Data.Count do
    begin
    	EItem := Data[I];

      if (EItem is TVariableItem) or (EItem is TConstItem) then
      begin
      	EItem.CreateLink(AEngine);
        Inc(I);
      end
      else if EItem is TIdentifierItem then
      begin
      	IdItem := TIdentifierItem(EItem);
        FuncLink := TOpFunction(IdItem.CreateLink(AEngine));
        EItem := Data[I+1];

        if (EItem is TParenthesisItem) and (TParenthesisItem(EItem).ParenthesisType = ptOpen) then
        begin
          Data.Delete(I+1);
        	Inc(I, 1);
          Stack := 1;
          Params := TObjectList<TExpressionItem>.Create;
          try
            while Stack > 0 do
            begin
              if I >= Data.Count then
              	raise ESmartyException.CreateResFmt(@sUncloseFunctionDeclaration, [IdItem.Name]);

              EItem := Data[I];

              if EItem is TParenthesisItem then
              begin
              	PnItem := TParenthesisItem(EItem);
              	case PnItem.ParenthesisType of
                  ptOpen:
                  	begin
                    	Inc(Stack);
                      TransferTo(Data, Params, I);
                    end;

                  ptClose:
                  	begin
                    	Dec(Stack);
                      if Stack > 0 then
                      	 TransferTo(Data, Params, I)
                      else begin
                     		Data.Delete(I);
                      	FuncLink.FParams.Add(AnalyzeParseData(Params));
                      	Params.Clear;
                      end;
                    end;

                  ptComma:
                  	if Stack = 1 then
                    begin
                     	Data.Delete(I);
                      FuncLink.FParams.Add(AnalyzeParseData(Params));
                      Params.Clear;
                    end
                    else
                    	TransferTo(Data, Params, I);
                end;
              end
              else begin
              	TransferTo(Data, Params, I);
              end;
            end;

          finally
            Params.Free;
          end;
        end
        else
        	raise	ESmartyException.CreateResFmt(@sFunctionParamsMiss, [IdItem.Name]);
      end
      else if EItem is TParenthesisItem then
      begin
        if TParenthesisItem(EItem).ParenthesisType = ptOpen then
        begin
          Data.Delete(I);
          Stack := 1;
          Params := TObjectList<TExpressionItem>.Create;
          try
            while Stack > 0 do
            begin
              if I >= Data.Count then
              	raise ESmartyException.CreateRes(@sPathensisDoNotClosed);

              EItem := Data[I];

              if EItem is TParenthesisItem then
              begin
              	PnItem := TParenthesisItem(EItem);
              	case PnItem.ParenthesisType of
                  ptOpen:
                  	begin
                    	Inc(Stack);
                      TransferTo(Data, Params, I);
                    end;

                  ptClose:
                  	begin
                    	Dec(Stack);
                      if Stack > 0 then
                      	TransferTo(Data, Params, I)
                      else begin
                        Data.Delete(I);
                      	Break;
                      end;
                    end;

                  ptComma:
                  	if Stack = 1 then
                  		raise ESmartyException.CreateRes(@sClosePathensisExpected)
                    else
                    	TransferTo(Data, Params, I);
                end;
              end
              else begin
              	TransferTo(Data, Params, I);
              end;
            end;

            OItem := TOpItem.Create;
            OItem.Link := AnalyzeParseData(Params);
            Data.Insert(I, OItem);

          finally
            Params.Free;
          end;

        end
        else begin
        	{$IFDEF SMARTYDEBUG} ShowExpr(Data); {$ENDIF}
        	raise ESmartyException.CreateRes(@sOpenPathensisExpected);
        end;

      end
      else
      	Inc(I);
    end;


    for J := 1 to MaxPrecedence do
    begin
    	I := 0;

    	while I < Data.Count do
    	begin
    		EItem := Data[I];

        if (EItem is TOperatorItem) and (TOperatorItem(EItem).GetPrecedence = J) then
        begin
        	OpItem := TOperatorItem(EItem);

          if OpItem.Op in [opLogicalNot, opBitwiseNot] then
          begin
          	if I + 1 < Data.Count then
            begin
          		RItem := Data[I+1];
              ROp := RItem.GetLink;
              if Assigned(ROp) then
              begin
              	OpItem.Link := TOpOperator.Create;
                OpItem.Link.FOperator := OpItem.Op;
                OpItem.Link.FRightOp := ROp;
                RItem.SetNilLink;
                Data.Delete(I+1);
                Inc(I);
              end
              else
              	raise ESmartyException.CreateRes(@sNotOperatorMissied);
            end
            else
            	raise ESmartyException.CreateRes(@sExpressionExcepted);
          end
          else begin

          	if (I + 1 < Data.Count) and (I > 0) then
            begin
            	LItem := Data[I-1];
          		RItem := Data[I+1];
              LOp := LItem.GetLink;
              ROp := RItem.GetLink;
              if Assigned(LOp) and Assigned(ROp) then
              begin
              	OpItem.Link := TOpOperator.Create;
                OpItem.Link.FOperator := OpItem.Op;
                OpItem.Link.FLeftOp := LOp;
                OpItem.Link.FRightOp := ROp;
                LItem.SetNilLink;
                RItem.SetNilLink;
                Data.Delete(I+1);
                Data.Delete(I-1);
              end
              else
              	raise ESmartyException.CreateRes(@sOperatorsMissed);
            end
            else
            	raise ESmartyException.CreateRes(@sExpressionExcepted);

          end;
        end
        else
        	Inc(I);
      end;
    end;

    if Data.Count = 1 then
    begin
    	Result := Data[0].GetLink;
      Data[0].SetNilLink;
    end
    else begin
    	{$IFDEF SMARTYDEBUG} ShowExpr(Data); {$ENDIF}
    	raise ESmartyException.CreateRes(@sInvalidExpression);
    end;
  end;

var
	Index: integer;
  Item, Item2: TExpressionItem;
  Expr: TObjectList<TExpressionItem>;

begin
	Result := nil;
	Expr := TObjectList<TExpressionItem>.Create;
  Index := 1;

  try
    while Index <= Length(S) do
    begin
      if TVariableItem.ParseItem(AEngine, S, Index, Item) or
         TConstItem.ParseItem(AEngine, S, Index, Item) or
         TIdentifierItem.ParseItem(AEngine, S, Index, Item) or
         TOperatorItem.ParseItem(AEngine, S, Index, Item) or
         TParenthesisItem.ParseItem(AEngine, S, Index, Item) then
      begin
       	//morth identifier to const or operator item
        if (Item is TIdentifierItem) and
        	 (TIdentifierItem(Item).IsConstItem(Item2) or
            TIdentifierItem(Item).IsOperatorItem(Item2)) then
        begin
        	FreeAndNil(Item);
          Item := Item2;
        end;

        Expr.Add(Item);
      end
      else if GetChar(S, Index) = #0 then Break
      else
        raise ESmartyException.CreateResFmt(@sInvalidCharInExpression, [GetChar(S, Index), S]);
    end;

    Result := AnalyzeParseData(Expr);
  finally
  	Expr.Free;
  end;
end;

{************* TOpVariable *************}

constructor TOpVariable.Create;
begin
	inherited Create;
  FNamespace := nil;
  FIndex := -1;
  FVarName := '';
  FVarDetails := TVarList.Create;
end;

destructor TOpVariable.Destroy;
begin
	FVarDetails.Finalize;
  inherited Destroy;
end;

function TOpVariable.Evaluate(AEngine: TSmartyEngine; var NeedFinalize: boolean): TVariableRecord;
begin
	Result := AEngine.GetVariable(FNamespace, FIndex, FVarName, FVarDetails, NeedFinalize);
end;

{$IFDEF SMARTYDEBUG}
function TOpVariable.AsString: string;
begin
  Result := ' VAR(' + FVarName + ') ';
end;
{$ENDIF}

{************* TOpConst *************}

constructor TOpConst.Create;
begin
	inherited Create;
end;

destructor TOpConst.Destroy;
begin
	FValue.Finalize;
  inherited Destroy;
end;

function TOpConst.Evaluate(AEngine: TSmartyEngine; var NeedFinalize: boolean): TVariableRecord;
begin
	Result := FValue;
  NeedFinalize := false;
end;

{$IFDEF SMARTYDEBUG}
function TOpConst.AsString: string;
begin
  Result := ' CONST(' + FValue.ToString + ') ';
end;
{$ENDIF}

{************* TOpFunction *************}

constructor TOpFunction.Create;
begin
	inherited Create;
  FFuncClass := nil;
  FParams := TOperationList.Create;
end;

destructor TOpFunction.Destroy;
begin
	FParams.Free;
  inherited Destroy;
end;

function TOpFunction.Evaluate(AEngine: TSmartyEngine; var NeedFinalize: boolean): TVariableRecord;
var
	VarArray: array of TVariableRecord;
  FinArray: array of boolean;
  I: integer;
begin
  if Assigned(FFuncClass) then
  begin
    SetLength(VarArray, FParams.Count);
    SetLength(FinArray, FParams.Count);
    try
      for I := 0 to FParams.Count - 1 do
        VarArray[I] := FParams[I].Evaluate(AEngine, FinArray[I]);
      Result := FFuncClass.EvaluateFunction(VarArray);
      NeedFinalize := (Result.VarType = vtString) or (Result.VarType = vtArray);
    finally
      for I := 0 to FParams.Count - 1 do
        if FinArray[I] then VarArray[I].Finalize;
      SetLength(VarArray, 0);
      SetLength(FinArray, 0);
    end;
  end
  else begin
    Result := TVariableRecord.Null;
    NeedFinalize := false;
  end;
end;

{$IFDEF SMARTYDEBUG}
function TOpFunction.AsString: string;
var
	I: integer;
begin
	Result := ' ' + FFuncClass.GetName + '(';
  for I := 0 to FParams.Count - 1 do
  	Result := Result + FParams[I].AsString + ',';
  if FParams.Count > 0 then
  	Delete(Result, Length(Result), 1);
  Result := Result + ') ';
end;
{$ENDIF}

{************* TOpOperator *************}

constructor TOpOperator.Create;
begin
	inherited Create;
  FLeftOp := nil;
  FRightOp := nil;
end;

destructor TOpOperator.Destroy;
begin
	if Assigned(FLeftOp) then FLeftOp.Free;
  if Assigned(FRightOp) then FRightOp.Free;
  inherited Destroy;
end;

function TOpOperator.Evaluate(AEngine: TSmartyEngine; var NeedFinalize: boolean): TVariableRecord;
var
  LeftVar, RightVar: TVariableRecord;
  LeftFinalize, RightFinalize: boolean;
begin // FI:C101
  LeftFinalize := false;
  RightFinalize := false;
	if not (FOperator in [opLogicalNot, opBitwiseNot]) then
  	LeftVar := FLeftOp.Evaluate(AEngine, LeftFinalize);
  RightVar := FRightOp.Evaluate(AEngine, RightFinalize);

	case FOperator of
    opEq:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coEq);
    opNeq:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coNeq);
    opGt:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coGt);
    opLt:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coLt);
    opGte:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coGte);
    opLte:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coLte);
    opSEq:
    	Result := TVariableRecord.DoCompare(LeftVar, RightVar, coSEq);
    opAdd:
    	Result := TVariableRecord.DoIntFloatOp(LeftVar, RightVar, voAdd);
    opSub:
    	Result := TVariableRecord.DoIntFloatOp(LeftVar, RightVar, voSubtract);
    opMply:
    	Result := TVariableRecord.DoIntFloatOp(LeftVar, RightVar, voMultiply);
    opDivide:
    	Result := TVariableRecord.DoFloatOp(LeftVar, RightVar, voDivide);
    opMod:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voModulus);
    opDiv:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voIntDivide);
    opShl:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voShl);
    opShr:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voShr);
    opLogicalNot:
    	Result := TVariableRecord.DoLogicalNot(RightVar);
    opLogicalAnd:
    	Result := TVariableRecord.DoLogicalOp(LeftVar, RightVar, voAnd);
    opLogicalOr:
    	Result := TVariableRecord.DoLogicalOp(LeftVar, RightVar, voOr);
    opBitwiseNot:
    	Result := TVariableRecord.DoIntNot(RightVar);
    opBitwiseAnd:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voAnd);
    opBitwiseOr:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voOr);
    opBitwiseXor:
    	Result := TVariableRecord.DoIntOp(LeftVar, RightVar, voXor);
  else
  	Result := TVariableRecord.Null;
  end;

  NeedFinalize := (Result.VarType = vtString) or (Result.VarType = vtArray);
  if RightFinalize then RightVar.Finalize;
  if LeftFinalize then LeftVar.Finalize;
end;

{$IFDEF SMARTYDEBUG}
function TOpOperator.AsString: string;
begin
  case FOperator of
    opEq:
    	Result := ' %s = %s ';
    opNeq:
    	Result := ' %s != %s ';
    opGt:
    	Result := ' %s > %s ';
    opLt:
    	Result := ' %s < %s ';
    opGte:
    	Result := ' %s >= %s ';
    opLte:
    	Result := ' %s <= %s ';
    opSEq:
    	Result := ' %s == %s ';
    opAdd:
    	Result := ' %s + %s ';
    opSub:
    	Result := ' %s - %s ';
    opMply:
    	Result := ' %s * %s ';
    opDivide:
    	Result := ' %s / %s ';
    opMod:
    	Result := ' %s % %s ';
    opDiv:
    	Result := ' %s \ %s ';
    opShl:
    	Result := ' %s << %s ';
    opShr:
    	Result := ' %s >> %s ';
    opLogicalNot:
    	Result := ' ! %s ';
    opLogicalAnd:
    	Result := ' %s && %s ';
    opLogicalOr:
    	Result := ' %s || %s ';
    opBitwiseNot:
    	Result := ' ~ %s ';
    opBitwiseAnd:
    	Result := ' %s & %s ';
    opBitwiseOr:
    	Result := ' %s | %s ';
    opBitwiseXor:
    	Result := ' %s ^ %s ';
  end;

  if FOperator in [opLogicalNot, opBitwiseNot] then
   	Result := Format(Result, [FRightOp.AsString])
  else
  	Result := Format(Result, [FLeftOp.AsString, FRightOp.AsString]);

  Result := ' (' + Result + ') ';
end;
{$ENDIF}

{************* TIfCondition *************}

constructor TIfCondition.Create(AEngine: TSmartyEngine);
begin
	inherited Create;
  FEngine := AEngine;
end;

{************* TSimpleIf *************}

constructor TSimpleIf.Create(AEngine: TSmartyEngine);
begin
	inherited Create(AEngine);
  FOperation := nil;
end;

constructor TSimpleIf.CreateOperation(AEngine: TSmartyEngine; const AExpr: string);
begin
	Create(AEngine);
  FOperation := TOperation.Parse(AEngine, AExpr);
end;

destructor TSimpleIf.Destroy;
begin
  if Assigned(FOperation) then FOperation.Free;
	inherited Destroy;
end;

function TSimpleIf.Evaluate: boolean;
var
	VarRec: TVariableRecord;
  NeedFinalize: boolean;
begin
	if Assigned(FOperation) then
  begin
  	VarRec := FOperation.Evaluate(FEngine, NeedFinalize);
    Result := VarRec.ToBool;
    if NeedFinalize then VarRec.Finalize;

  end
  else
  	Result := false;
end;

{************* TVariableIf *************}

constructor TVariableIf.Create(AEngine: TSmartyEngine);
begin
	inherited Create(AEngine);
  FNamespace := nil;
  FVarDetails := TVarList.Create;
end;

constructor TVariableIf.CreateIf(AEngine: TSmartyEngine; AType: TIfType);
begin
	Create(AEngine);
  FIfType := AType;
end;

destructor TVariableIf.Destroy;
begin
  FVarDetails.Finalize;
	inherited Destroy;
end;

function TVariableIf.Evaluate: boolean;
var
  VarRec: TVariableRecord;
  ArrayData: PVariableArray;
  NeedFinalize: boolean;
begin
	VarRec := FEngine.GetVariable(FNamespace, FIndex, FVarName, FVarDetails, NeedFinalize);
  try
    if VarRec.IsArray then
    begin
      ArrayData := VarRec.AValue;
      case FIfType of
        ifDef:
        	Result := true;
        ifNDef:
        	Result := false;
        ifEmpty:
        	Result := (ArrayData.Count > 0);
        ifNEmpty:
        	Result := (ArrayData.Count = 0);
      else
        Result := false;
      end;
    end
    else begin
      case FIfType of
        ifDef:
        	Result := VarRec.VarType <> vtNull;
        ifNDef:
        	Result := VarRec.VarType = vtNull;
        ifEmpty:
        	Result := VarRec.IsEmpty;
        ifNEmpty:
        	Result := not VarRec.IsEmpty;
      else
        Result := false;
      end;
    end;
  finally
    if NeedFinalize then VarRec.Finalize;
  end;
end;

procedure TVariableIf.SetVariable(AEngine: TSmartyEngine; AVariable: string);
var
	I: integer;
begin
	AVariable := SmartyTrim(AVariable);
  if (Length(AVariable) > 2) and (AVariable[1] = '$') then
  begin
    for I := 2 to Length(AVariable) do
      if not CharInSet(AVariable[I], ['A'..'Z','a'..'z','_','.', '[', ']', '0'..'9']) then
      begin
        raise ESmartyException.CreateResFmt(@sInvalidVarDeclaration, [AVariable]);
      end;
  end
  else
    raise ESmartyException.CreateResFmt(@sInvalidVarDeclaration, [AVariable]);

  Delete(AVariable, 1, 1);                       //delete $ sign
  TTemplateAction.GetVariableProperties(AEngine, AVariable, FNamespace, FIndex,
  	FVarName, FVarDetails);
  AVariable := '';
end;

{************* TElseIfAction *************}

constructor TElseIfAction.Create;
begin
	inherited Create;
  FCondition := nil;
  FActions := TTemplateActions.Create(true);
end;

destructor TElseIfAction.Destroy;
begin
	if Assigned(FCondition) then FCondition.Free;
  FActions.Free;
	inherited Destroy;
end;

{************* TIfOutputAction *************}

constructor TIfOutputAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatIf;

  FCondition := nil;
  FThenActions := TTemplateActions.Create;
  FElseActions := TTemplateActions.Create;
  FElseIfActions := TElseIfActions.Create(true);
end;

destructor TIfOutputAction.Destroy;
begin
	if Assigned(FCondition) then FCondition.Free;
	FElseIfActions.Free;
  FThenActions.Free;
  FElseActions.Free;
  inherited Destroy;
end;

function TIfOutputAction.ContinueIf(AEngine: TSmartyEngine; ACommand: string; // FI:O801
	var AState: integer; var AActions: TTemplateActions): boolean;
var
	ElseAction: TElseIfAction;

  function AddVarIf(AIfType: TIfType; S: string): boolean;
  begin
  	if AState >= 2 then
   		raise ESmartyException.CreateRes(@sElseIfAfterElseBlock);
    AState := 1;

    ElseAction := TElseIfAction.Create;
    FElseIfActions.Add(ElseAction);
    ElseAction.FCondition := TVariableIf.CreateIf(AEngine, AIfType);
    TVariableIf(ElseAction.FCondition).SetVariable(AEngine, S);
    AActions := ElseAction.FActions;
    Result := true;
  end;


begin
  if IsTag('/if', ACommand, true) then
  begin
  	AState := 3;
    AActions := nil;
    Result := false;
  end
  else if IsTag('else', ACommand, true) then
  begin
    if AState >= 2 then
    	raise ESmartyException.CreateRes(@sElseAfterElseBlock);
    AState := 2;
    AActions := FElseActions;
    Result := true;
  end
  else if IsTagAndGetCommand('elseif', ACommand) then
  begin
  	if AState >= 2 then
   		raise ESmartyException.CreateRes(@sElseIfAfterElseBlock);
    AState := 1;

    ElseAction := TElseIfAction.Create;
    FElseIfActions.Add(ElseAction);
    ElseAction.FCondition := TSimpleIf.CreateOperation(AEngine, ACommand);

    AActions := ElseAction.FActions;
    Result := true;
  end
  else if IsTagAndGetCommand('elseifdef', ACommand) then Result := AddVarIf(ifDef, ACommand)
  else if IsTagAndGetCommand('elseifndef', ACommand) then Result := AddVarIf(ifNDef, ACommand)
  else if IsTagAndGetCommand('elseifempty', ACommand) then Result := AddVarIf(ifEmpty, ACommand)
  else if IsTagAndGetCommand('elseifnempty', ACommand) then Result := AddVarIf(ifNEmpty, ACommand)
  else
  	Result := false;
end;

function TIfOutputAction.Execute: string;
var
	I: integer;
begin
  if FCondition.Evaluate then
    Result := FThenActions.Execute
  else begin
  	for I := 0 to FElseIfActions.Count - 1 do
    	if FElseIfActions[I].FCondition.Evaluate then
      	Exit(FElseIfActions[I].FActions.Execute);
   	Result := FElseActions.Execute;
  end;
end;

class function TIfOutputAction.IsAction(AEngine: TSmartyEngine;
	ACommand: string; var AAction: TTemplateAction): boolean;

  function AddVarIf(AIfType: TIfType; S: string): TIfOutputAction;
  begin
  	Result := TIfOutputAction.Create(AEngine);
    Result.FCondition := TVariableIf.CreateIf(AEngine, AIfType);
    TVariableIf(Result.FCondition).SetVariable(AEngine, S);
  end;

begin
	AAction := nil;
	if IsTagAndGetCommand('if', ACommand) then
  begin
  	AAction := TIfOutputAction.Create(AEngine);
    TIfOutputAction(AAction).FCondition := TSimpleIf.CreateOperation(AEngine, ACommand);
  end
  else if IsTagAndGetCommand('ifdef', ACommand) then
  	AAction := AddVarIf(ifDef, ACommand)
  else if IsTagAndGetCommand('ifndef', ACommand) then
  	AAction := AddVarIf(ifNDef, ACommand)
  else if IsTagAndGetCommand('ifempty', ACommand) then
  	AAction := AddVarIf(ifEmpty, ACommand)
  else if IsTagAndGetCommand('ifnempty', ACommand) then
  	AAction := AddVarIf(ifNEmpty, ACommand);

  Result := Assigned(AAction);
end;

{************* TForEachAction *************}

constructor TForEachOutputAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatForEach;
  FNamespaceBased := false;

  FVarDetails := TVarList.Create;
  FBaseActions := TTemplateActions.Create;
  FElseActions := TTemplateActions.Create;
end;

destructor TForEachOutputAction.Destroy;
begin
	FVarDetails.Finalize;
  FBaseActions.Free;
  FElseActions.Free;
  inherited Destroy;
end;

function TForEachOutputAction.Execute: string;
var
	List: TForEachData;
  I, LMin, LMax: integer;
  VarRec: TVariableRecord;
	NeedFinalize: boolean;
begin // FI:C101
  if not FNamespaceBased then
	  VarRec := FEngine.GetVariable(FNamespace, FIndex, FVarName, FVarDetails, NeedFinalize);
  Result := '';

  try
  	List := TForEachData.Create;
    List.Name := FForEachName;
    List.InForEach := false;
    List.ItemVarName := FVariableName;
    List.KeyVarName := FAssocName;
    List.IsNamespace := FNamespaceBased;
    List.MinIndex := 0;

    if FNamespaceBased then
    begin
      List.Namespace := FNamespace;
      List.VarData := nil;
      FNamespace.GetIndexProperties(LMin, LMax);
      List.Show := (LMax - LMin) >= 0;
      List.MinIndex := LMin;
      if List.Show then
        List.Total := (LMax - LMin) + 1
      else
        List.Total := 0;
    end
    else begin
      List.Namespace := nil;
      List.VarData := VarRec.AValue;
      List.Show := VarRec.IsArray and (List.VarData.Count > 0);
      if List.Show then
        List.Total := List.VarData.Count
      else begin
        List.VarData := nil;
        List.Total := 0;
      end;
    end;

    if (FMaxItems > 0) and (FMaxItems < List.Total) then
      List.Total := FMaxItems;

    FEngine.FSmartyNamespace.FForEachList.EnterForEach(List);
    try
      if List.Show then
      begin
        List.InForEach := true;

        for I := 1 to List.Total do
        begin
          List.Iteration := I;
          List.First := (I = 1);
          List.Last := (I = List.Total);
          Result := Result + FBaseActions.Execute;
        end
      end
      else
        Result := FElseActions.Execute;
    finally
       List.InForEach := false;
       FEngine.FSmartyNamespace.FForEachList.ExitForEach;
    end;
  finally
    if not FNamespaceBased and NeedFinalize then VarRec.Finalize;
  end;
end;

function TForEachOutputAction.ContinueForEach(AEngine: TSmartyEngine;
	ACommand: string; var AState: integer; var AActions: TTemplateActions): boolean; // FI:O801
begin
  if IsTag('/foreach', ACommand, true) then
  begin
  	AState := 2;
    AActions := nil;
    Result := false;
  end
  else if IsTag('foreachelse', ACommand, true) then
  begin
    if AState >= 2 then
    	raise ESmartyException.CreateRes(@sForEachElseAfterBlockEnd);
    AState := 1;
    AActions := FElseActions;
    Result := true;
  end
  else
  	Result := false;
end;

class function TForEachOutputAction.IsAction(AEngine: TSmartyEngine;
	ACommand: string;	var AAction: TTemplateAction): boolean;
var
	SL: TStringList;
  S, VarName: string;
  I, NamespaceIndex: integer;
  NamespaceProvider: TNamespaceProvider;
begin // FI:C101
	AAction := nil;
  Result := false;
	if IsTagAndGetCommand('foreach', ACommand) then
  begin
  	SL := ParseFunction(ACommand);
    try
    	CheckFunction(SL, ['from', 'item', 'key', 'name', 'maxitems']);
      AAction := TForEachOutputAction.Create(AEngine);

      TForEachOutputAction(AAction).FNamespaceBased := false;
      TForEachOutputAction(AAction).FForEachName := GetAttributeValue(SL, 'name');
      TForEachOutputAction(AAction).FVariableName := GetAttributeValue(SL, 'item', 'item');
      TForEachOutputAction(AAction).FAssocName := GetAttributeValue(SL, 'key', 'key');
      S := GetAttributeValue(SL, 'maxitems', '0');
      if TryStrToInt(S, I) and (I > 0) then
        TForEachOutputAction(AAction).FMaxItems := I
      else
        TForEachOutputAction(AAction).FMaxItems := 0;

      VarName := GetAttributeValue(SL, 'from');
      if (Length(VarName) > 1) and (VarName[1] = '$') then
      	Delete(VarName, 1, 1)
      else begin
      	FreeAndNil(AAction);
      	raise ESmartyException.CreateRes(@sFromVariableRequireForEach);
      end;

      GetVariableProperties(AEngine, VarName, TForEachOutputAction(AAction).FNamespace,
      	TForEachOutputAction(AAction).FIndex, TForEachOutputAction(AAction).FVarName,
        TForEachOutputAction(AAction).FVarDetails);

      //find namespace foreach
      with TForEachOutputAction(AAction) do
        if FNamespace = nil then
        begin
          NamespaceIndex := AEngine.FNamespaces.IndexOf(FVarName);
          if NamespaceIndex >= 0 then
          begin
            NamespaceProvider := TNamespaceProvider(AEngine.FNamespaces.Objects[NamespaceIndex]);
            if NamespaceProvider.IsIndexSupported then
            begin
              //namespace foreach
              FNamespace := NamespaceProvider;
              FVarName := '';
              FNamespaceBased := true;
            end;
          end;
        end;

    finally
      SL.Free;
    end;

  	Result := true;
  end;
end;


{************* TCaptureArrayAction *************}

constructor TCaptureArrayAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatCaptureArray;
  FVarDetails := TVarList.Create;
  FFilter := nil;
end;

destructor TCaptureArrayAction.Destroy;
begin
	FVarDetails.Finalize;
  if Assigned(FFilter) then FFilter.Free;
  inherited Destroy;
end;

function TCaptureArrayAction.Execute: string; // FI:C103
var
  VarRec, NewVar, ResVar: TVariableRecord;
	NeedFinalize, NeedResFinalize, Include: boolean;
  ARec: PVariableArray;
  I: Integer;
  Indexes: TList<integer>;
begin // FI:C101
  VarRec := FEngine.GetVariable(FNamespace, FIndex, FVarName, FVarDetails, NeedFinalize);
  try
    if VarRec.IsArray then
    begin
      ARec := VarRec.AValue;
      Indexes := TList<integer>.Create;
      try
        FEngine.FSmartyNamespace.FActiveCapture.Enter(FItemName, 0, ARec);
        try
          for I := 0 to ARec.Count - 1 do
          begin
            if Assigned(FFilter) then
            begin
              ResVar := FFilter.Evaluate(FEngine, NeedResFinalize);
              try
                Include := ResVar.ToBool;
              finally
                if NeedResFinalize then ResVar.Finalize;
              end;
            end
            else
              Include := true;

            if Include then Indexes.Add(I);
            FEngine.FSmartyNamespace.FActiveCapture.IncIndex;
          end;
        finally
          FEngine.FSmartyNamespace.FActiveCapture.Exit;
        end;

        if Indexes.Count > 0 then
        begin
          NewVar.SetArrayLength(Indexes.Count);
          for I := 0 to Indexes.Count - 1 do
          begin
            NewVar.SetArrayItemQ(I, string(ARec.Data[Indexes[I]].Key),
              ARec.Data[Indexes[I]].Item.Clone);
          end;
        end
        else
          NewVar := TVariableRecord.Null;

      finally
        Indexes.Free;
      end;
    end
    else begin
      NewVar := TVariableRecord.Null;
    end;

    FEngine.FSmartyNamespace.SetCaptureItem(FVariableName, NewVar);
    Result := '';
  finally
    if NeedFinalize then VarRec.Finalize;
  end;
end;

class function TCaptureArrayAction.IsAction(AEngine: TSmartyEngine;
  ACommand: string; var AAction: TTemplateAction): boolean;
var
	SL: TStringList;
  VarName, S: string;
begin
	AAction := nil;
  Result := false;
	if IsTagAndGetCommand('capturearray', ACommand) then
  begin
  	SL := ParseFunction(ACommand);
    try
    	CheckFunction(SL, ['from', 'item', 'variable', 'filter']);
      AAction := TCaptureArrayAction.Create(AEngine);

      TCaptureArrayAction(AAction).FItemName := GetAttributeValue(SL, 'item', 'item');
      TCaptureArrayAction(AAction).FVariableName := GetAttributeValue(SL, 'variable', 'var');
      VarName := GetAttributeValue(SL, 'from');
      if (Length(VarName) > 1) and (VarName[1] = '$') then
      	Delete(VarName, 1, 1)
      else begin
      	FreeAndNil(AAction);
      	raise ESmartyException.CreateRes(@sFromVariableRequireForEach);
      end;

      GetVariableProperties(AEngine, VarName, TCaptureArrayAction(AAction).FNamespace,
      	TCaptureArrayAction(AAction).FIndex, TCaptureArrayAction(AAction).FVarName,
        TCaptureArrayAction(AAction).FVarDetails);

      S := GetAttributeValue(SL, 'filter');
      if S <> '' then
        TCaptureArrayAction(AAction).FFilter := TOperation.Parse(AEngine, S);
    finally
      SL.Free;
    end;

  	Result := true;
  end;
end;


{************* TReleaseArrayAction *************}

constructor TReleaseArrayAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatReleaseArray;
end;

destructor TReleaseArrayAction.Destroy;
begin
  inherited Destroy;
end;

function TReleaseArrayAction.Execute: string;
begin
  FEngine.FSmartyNamespace.RemoveCaptureItem(FVariableName);
  Result := '';
end;

class function TReleaseArrayAction.IsAction(AEngine: TSmartyEngine;
  ACommand: string; var AAction: TTemplateAction): boolean;
var
	SL: TStringList;
begin
	AAction := nil;
  Result := false;
	if IsTagAndGetCommand('releasearray', ACommand) then
  begin
  	SL := ParseFunction(ACommand);
    try
    	CheckFunction(SL, ['variable']);
      AAction := TReleaseArrayAction.Create(AEngine);
      TReleaseArrayAction(AAction).FVariableName := GetAttributeValue(SL, 'variable', 'var');
    finally
      SL.Free;
    end;

  	Result := true;
  end;
end;

{************* TAssignAction *************}

constructor TAssignAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatAssign;
  FValue := nil;
end;

destructor TAssignAction.Destroy;
begin
  if Assigned(FValue) then FValue.Free;
  inherited Destroy;
end;

function TAssignAction.Execute: string;
var
  VarValue: TVariableRecord;
	NeedFinalize: boolean;
begin
  if Assigned(FValue) then
  begin
    VarValue := FValue.Evaluate(FEngine, NeedFinalize);
    FEngine.FSmartyNamespace.SetCaptureItem(FVariableName, VarValue);
  end;

  Result := '';
end;

class function TAssignAction.IsAction(AEngine: TSmartyEngine;
  ACommand: string; var AAction: TTemplateAction): boolean;
var
	SL: TStringList;
  S: string;
begin
	AAction := nil;
  Result := false;

  //long assign form
	if IsTagAndGetCommand('assign', ACommand) then
  begin
  	SL := ParseFunction(ACommand);
    try
    	CheckFunction(SL, ['variable', 'value']);
      AAction := TAssignAction.Create(AEngine);

      TAssignAction(AAction).FVariableName := GetAttributeValue(SL, 'variable', 'var');
      S := GetAttributeValue(SL, 'value');
      if S <> '' then
        TAssignAction(AAction).FValue := TOperation.Parse(AEngine, S);
    finally
      SL.Free;
    end;

  	Result := true;
  end
  //short assign form
  else begin
    //Not yet done, need to resolve conflict with variable output
  end;
end;

{************* TReleaseAction *************}

constructor TReleaseAction.Create(AEngine: TSmartyEngine);
begin
  inherited Create(AEngine);
  FActionType := tatRelease;
end;

destructor TReleaseAction.Destroy;
begin
  inherited Destroy;
end;

function TReleaseAction.Execute: string;
begin
  FEngine.FSmartyNamespace.RemoveCaptureItem(FVariableName);
  Result := '';
end;

class function TReleaseAction.IsAction(AEngine: TSmartyEngine;
  ACommand: string; var AAction: TTemplateAction): boolean;
var
	SL: TStringList;
begin
	AAction := nil;
  Result := false;
	if IsTagAndGetCommand('release', ACommand) then
  begin
  	SL := ParseFunction(ACommand);
    try
    	CheckFunction(SL, ['variable']);
      AAction := TReleaseAction.Create(AEngine);
      TReleaseAction(AAction).FVariableName := GetAttributeValue(SL, 'variable', 'var');
    finally
      SL.Free;
    end;

  	Result := true;
  end;
end;


{************* TSmartyInfoProvider *************}

constructor TSmartyInfoProvider.Create;
begin
	inherited Create;

  FModifiers := TModifierList.Create;
  FFunctions := TFunctionList.Create;

  Init;
end;

procedure TSmartyInfoProvider.Init;
begin // FI:C101
  //default modifiers
  AddModifier(TCapitalizeModifier);
  AddModifier(TCatModifier);
  AddModifier(TTrimModifier);
  AddModifier(TCountCharactersModifier);
  AddModifier(TCountParagraphsModifier);
  AddModifier(TCountWordsModifier);
  AddModifier(TDefaultModifier);
  AddModifier(THTMLEncodeModifier);
  AddModifier(THTMLEncodeAllModifier);
  AddModifier(TXMLEncodeModifier);
  AddModifier(TFileEncodeModifier);
  AddModifier(TDateFormatModifier);
  AddModifier(TFloatFormatModifier);
  AddModifier(TLowerModifier);
  AddModifier(TUpperModifier);
  AddModifier(TNl2BrModifier);
  AddModifier(TTruncateModifier);
  AddModifier(TStripModifier);
  AddModifier(TSpacifyModifier);
  AddModifier(TWordwrapModifier);
  AddModifier(TIndentModifier);
  AddModifier(TReplaceModifier);
  AddModifier(TStripTagsModifier);

  //default functions
  AddFunction(TIsNullFunction);
  AddFunction(TIsEmptyFunction);
  AddFunction(TIsBooleanFunction);
  AddFunction(TIsIntegerFunction);
  AddFunction(TIsFloatFunction);
  AddFunction(TIsNumberFunction);
  AddFunction(TIsDateStrictFunction);
  AddFunction(TIsDateLooseFunction);
  AddFunction(TIsDateTimeFunction);
  AddFunction(TIsDateFunction);
  AddFunction(TIsStringFunction);
  AddFunction(TIsArrayFunction);
  AddFunction(TArrayLengthFunction);
  AddFunction(TArrayIndexFunction);
  AddFunction(TArrayKeyFunction);
  AddFunction(TCountFunction);

  //String Functions
  AddFunction(TEchoFunction);
  AddFunction(TPrintFunction);
  AddFunction(THTMLEncodeFunction);
  AddFunction(THTMLEncodeAllFunction);
  AddFunction(TXMLEncodeFunction);
  AddFunction(TFileEncodeFunction);
  AddFunction(TTrimFunction);
  AddFunction(TTruncateFunction);
  AddFunction(TCapitalizeFunction);
  AddFunction(TCountCharactersFunction);
  AddFunction(TCountWordsFunction);
  AddFunction(TCountParagraphsFunction);
  AddFunction(TUpperCaseFunction);
  AddFunction(TLowerCaseFunction);
  AddFunction(TStripFunction);
  AddFunction(TStripTagsFunction);
  AddFunction(TSpacifyFunction);
  AddFunction(TWordwrapFunction);
  AddFunction(TIndentFunction);
  AddFunction(TFloatFormatFunction);
  AddFunction(TIfThenFunction);

  AddFunction(TResemblesFunction);
  AddFunction(TContainsFunction);
  AddFunction(TStartsFunction);
  AddFunction(TEndsFunction);
  AddFunction(TReplaceFunction);


  //DateTime Functions
  AddFunction(TDateFormatFunction);
  AddFunction(TFullYearsFunction);
  AddFunction(TYearOfFunction);
  AddFunction(TMonthOfFunction);
  AddFunction(TDayOfFunction);
end;

procedure TSmartyInfoProvider.AddModifier(AModifier: TVariableModifierClass);
begin
  FModifiers.Add(AModifier);
end;

procedure TSmartyInfoProvider.AddFunction(AFunction: TSmartyFunctionClass);
begin
  FFunctions.Add(AFunction);
end;

procedure TSmartyInfoProvider.DeleteFunction(AFunction: TSmartyFunctionClass);
var
  I: integer;
begin
  I := FFunctions.IndexOf(AFunction.GetName);
  if I >= 0 then FFunctions.Delete(I);
end;

destructor TSmartyInfoProvider.Destroy;
begin
	FModifiers.Free;
  FFunctions.Free;
  inherited Destroy;
end;


{************* TSmartyEngine *************}

constructor TSmartyEngine.Create;
begin
	inherited Create;

  FCompiled := false;
  FActions := TTemplateActions.Create;
  FIsCache := true;
  FVarCache := TList<TVariableCache>.Create;

  FNamespaces := TNamespaceList.Create;

  FSilentMode := true;
  FErrors := TStringList.Create;
  FAutoHTMLEncode := false;
  FAllowEspacesInStrings := true;
  Init;
end;

procedure TSmartyEngine.Init;
begin
	//default namespaces
  FSmartyNamespace := TSmartyProvider.Create(Self);
	AddNamespace(FSmartyNamespace);
end;

procedure TSmartyEngine.SetIsCache(Value: boolean);
begin
	if Value <> FIsCache then
  begin
  	FIsCache := Value;
    if not FIsCache then ClearCache;
  end;
end;

procedure TSmartyEngine.ClearCache;
var
	I: integer;
begin
  if FVarCache.Count > 0 then
    for I := 0 to FVarCache.Count - 1 do
    begin
      FVarCache[I].VariableValue.Finalize;
      FreeMem(FVarCache[I].VariableValue, SizeOf(TVariableRecord));
    end;
  FVarCache.Clear;
end;

procedure TSmartyEngine.ClearCache(ANamespace: TNamespaceProvider);
var
	I: integer;
begin
  if FVarCache.Count > 0 then
    for I := FVarCache.Count - 1 downto 0 do
      if FVarCache[I].Namespace = ANamespace then
      begin
        FVarCache[I].VariableValue.Finalize;
        FreeMem(FVarCache[I].VariableValue, SizeOf(TVariableRecord));
        FVarCache.Delete(I);
      end;
end;

function TSmartyEngine.GetVariable(const ANamespace: TNamespaceProvider;
	AIndex: integer; const AVariableName: string; ADetails: TVarList;
  var NeedFinalize: boolean): TVariableRecord;
var
	I: integer;
  CacheItem: TVariableCache;
  VarFound: boolean;
  V: TVariableRecord;
begin // FI:C101
	if ANamespace = FSmartyNamespace then
  begin
  	Result := FSmartyNamespace.GetSmartyVariable(AVariableName, ADetails,
    	NeedFinalize);
  end
  else if ANamespace = nil then
  begin
  	Result := FSmartyNamespace.GetDetachVariable(AVariableName, ADetails,
    	NeedFinalize);
  end
  else begin
  	//Find in cache
    VarFound := false;
    NeedFinalize := false;

    if FIsCache then
      for I := 0 to FVarCache.Count - 1 do
      begin
        CacheItem := FVarCache[I];
        if (CacheItem.Namespace = ANamespace) and
           ((AIndex = -1) or (AIndex = CacheItem.Index)) and
           (CacheItem.VariableName = AVariableName) then
        begin
          VarFound := true;
          Break;
        end;
      end;

    //If Found
    if VarFound then
    begin
    	if ADetails.Count > 0 then
      	Result := GetVariableDetails(CacheItem.VariableValue^, ADetails)
      else
    		Result := CacheItem.VariableValue^;
    end
    else if Assigned(ANamespace) then  //If not found
    begin
    	if FIsCache and ANamespace.UseCache then
      begin
        CacheItem.Namespace := ANamespace;
        CacheItem.Index := AIndex;
        CacheItem.VariableName := AVariableName;
        CacheItem.VariableValue := AllocMem(SizeOf(TVariableRecord));
        CacheItem.VariableValue^ := ANamespace.GetVariable(AIndex, AVariableName);
        FVarCache.Add(CacheItem);

        if ADetails.Count > 0 then
          Result := GetVariableDetails(CacheItem.VariableValue^, ADetails)
        else
          Result := CacheItem.VariableValue^;
      end
      else begin
        V := ANamespace.GetVariable(AIndex, AVariableName);
        if ADetails.Count > 0 then
        begin
          Result := GetVariableDetails(V, ADetails).Clone;
          V.Finalize;
        end
        else
          Result := V;

				NeedFinalize := ((Result.VarType = vtString) or (Result.VarType = vtArray));
      end;
    end
    else
    	Result := TVariableRecord.Null;
  end;
end;

function TSmartyEngine.GetVariableDetails(AVariable: TVariableRecord;
	ADetails: TVarList): TVariableRecord;
var
	Value: string;
	I, J, Index: integer;
  ValueSet: boolean;
  ArrayData: PVariableArray;
begin
	if ADetails.Count > 0 then
  begin
  	Result := AVariable;

    for I := 0 to ADetails.Count - 1 do
    begin
    	if not Result.IsArray then Exit(TVariableRecord.Null);

    	case ADetails[I].PartType of
      	vptValue:
        begin
        	Value := ADetails[I];
          ArrayData := Result.AValue;
          ValueSet := false;
         	for J := 0 to ArrayData.Count - 1 do
            if (string(ArrayData.Data[J].Key) <> '') and 
            	(CompareText(string(ArrayData.Data[J].Key), Value) = 0) then
            begin
            	Result := ArrayData.Data[J].Item;
              ValueSet := true;
             	Break;
            end;

          if not ValueSet then Exit(TVariableRecord.Null);
        end;

        vptIndex:
        begin
          Index := ADetails[I];
          ArrayData := Result.AValue;
          if (Index >= 0) and (Index < ArrayData.Count) then
          	Result := ArrayData.Data[Index].Item
          else
          	Exit(TVariableRecord.Null);
        end;
      else
      	Exit(TVariableRecord.Null);
      end;
    end;
  end
  else
  	Result := AVariable;
end;

function TSmartyEngine.IsFunction(ACommand: string; var Func: TSmartyFunctionClass;
	var Params: string; var Modifiers: string): boolean;
var
	I, J, K: integer;
  Ch: Char;
  InQuote: boolean;
  Stack: integer;
  SFunc: string;
begin // FI:C101
	ACommand := SmartyTrim(ACommand);
  Result := false;
  K := Pos('(', ACommand);
	if K > 0 then
  begin
  	SFunc := SmartyTrim(Copy(ACommand, 1, K - 1));
    I := SmartyProvider.FFunctions.IndexOf(SFunc);

    if I >= 0 then
    begin
      Func := SmartyProvider.FFunctions.GetFunction(I);

      InQuote := false;
      Stack := 0;

      for J := K to Length(ACommand) do
      begin
      	Ch := ACommand[J];

      	if not InQuote then
        begin
        	if Ch = '(' then Inc(Stack)
          else if Ch = ')' then
          begin
            Dec(Stack);
            if Stack <= 0 then
            begin
            	Params := SmartyTrim(Copy(ACommand, Length(SmartyProvider.FFunctions[I]) + 2,
              	J - Length(SmartyProvider.FFunctions[I]) - 2));

              if Length(ACommand) > J then
              	Modifiers := SmartyTrim(Copy(ACommand, J + 1, Length(ACommand) - J))
              else
              	Modifiers := '';

            	Break;
            end;
          end
          else if Ch = '"' then
          	InQuote := true;
        end
        else if Ch = '"' then
        	InQuote := false;
      end;

      if Stack > 0 then
      	raise ESmartyException.CreateResFmt(@sInvalidFunctionDeclaration, [ACommand]);

    	Exit(true);
    end;
  end;
end;

function TSmartyEngine.GetFunction(const AFunction: string): TSmartyFunctionClass;
var
	I: integer;
begin
	I := SmartyProvider.FFunctions.IndexOf(AFunction);

  if I >= 0 then
    Result := SmartyProvider.FFunctions.GetFunction(I)
  else
  	Result := nil;
end;

destructor TSmartyEngine.Destroy;
begin
	FActions.Free;

  ClearCache;
 	FVarCache.Free;

	FErrors.Free;

	FNamespaces.Free;
  inherited Destroy;
end;

procedure TSmartyEngine.AddNamespace(ANamespace: TNamespaceProvider);
begin
  FNamespaces.Add(ANamespace);
end;

procedure TSmartyEngine.DeleteNamespace(ANamespace: TNamespaceProvider);
var
	I: integer;
begin
	I := FNamespaces.IndexOf(ANamespace.GetName);
  if I >= 0 then FNamespaces.Delete(I);
end;

function TSmartyEngine.Compile(const ADocument: string; var Errors: TStringList): boolean;

	function SkipAllLiteralEnd(S: string; var IndexStart, IndexEnd: integer): boolean; // FI:W521
  var
  	Pos1, Pos2: integer;
    Str: string;
  begin
  	while true do
    begin
      Pos1 := PosEx('{', S, IndexStart);
      if Pos1 > 0 then
      begin
        Pos2 := PosEx('}', S, Pos1);
        if Pos2 <= 0 then Exit(false);
        Str := Copy(S, Pos1 + 1, Pos2 - Pos1 - 1);
        Str := SmartyTrim(Str);
        if CompareText(Str, '/literal') = 0 then
        begin
        	IndexStart := Pos1;
          IndexEnd := Pos2;
          Exit(true);
        end
        else
          Inc(IndexStart);
      end
      else
        Exit(false);
    end;
  end;

	function CompilePart(S: string; AActions: TTemplateActions; // FI:C103
  	BreakAction: TNestAction; var AStart: integer): string;
  var
  	Output, Return, Smarty: string;
  	Ch: Char;
  	J, K, State: integer;
  	InSmarty, InSmartyQuote: boolean;
    Action: TTemplateAction;
    Acts: TTemplateActions;
  begin
	  InSmarty := false;
  	InSmartyQuote := false;
    Output := '';
    Smarty := '';

    while AStart <= Length(S) do
    begin
      Ch := S[AStart];
      Inc(AStart);

      if InSmarty and (Ch = '"') then
      begin
        InSmartyQuote := not InSmartyQuote;
        Smarty := Smarty + Ch;
      end
      else if not InSmartyQuote and (Ch = '{') then
      begin
        if not InSmarty then
        begin
          Smarty := '';
          InSmarty := true;
        end
        else
          raise ESmartyException.CreateRes(@sOpenBraceInTemplate);
      end
      else if not InSmartyQuote and (Ch = '}') then
      begin
        if InSmarty then
        begin
          if CompareText(SmartyTrim(Smarty), 'literal') = 0 then
          begin
            J := AStart;
            if SkipAllLiteralEnd(S, J, K) then
            begin
            	Output := Output + Copy(S, AStart, J - AStart);
              AStart := K + 1;
            end
            else
              raise ESmartyException.CreateRes(@sLiteralDoNotFound);
          end
          else begin
          	if Output <> '' then AActions.Add(TRawOutputAction.CreateOutput(Self, Output));
            Output := '';

            if not TTemplateAction.IsComment(Smarty) then

            	if TTemplateAction.IsExitCommand(Smarty, BreakAction) then
              begin
              	Exit(Smarty);
              end

            	else if TRawOutputAction.IsAction(Self, Smarty, Action) or
              	TVariableOutputAction.IsAction(Self, Smarty, Action) or
                TFuncOutputAction.IsAction(Self, Smarty, Action) or
                TCaptureArrayAction.IsAction(Self, Smarty, Action) or
                TReleaseArrayAction.IsAction(Self, Smarty, Action) or
                TAssignAction.IsAction(Self, Smarty, Action) or
                TReleaseAction.IsAction(Self, Smarty, Action) then
              begin
              	AActions.Add(Action);
              end

              else if TIfOutputAction.IsAction(Self, Smarty, Action) then
              begin
              	AActions.Add(Action);
                State := 0;
               	Return := CompilePart(S, TIfOutputAction(Action).FThenActions, naIf, AStart);

                while TIfOutputAction(Action).ContinueIf(Self, Return, State, Acts) do
									Return := CompilePart(S, Acts, naIf, AStart);
              end
              else if TForEachOutputAction.IsAction(Self, Smarty, Action) then
              begin
              	AActions.Add(Action);
                State := 0;
               	Return := CompilePart(S, TForEachOutputAction(Action).FBaseActions, naForEach, AStart);

                while TForEachOutputAction(Action).ContinueForEach(Self, Return, State, Acts) do
									Return := CompilePart(S, Acts, naForEach, AStart);
              end
              else
              	raise ESmartyException.CreateResFmt(@sInvalidTemplateDirective, [Smarty]);

          end;

          if InSmartyQuote then
            raise ESmartyException.CreateRes(@sUncloseQuote);
          InSmarty := false;
        end
        else
          raise ESmartyException.CreateRes(@sCloseBraceWithoutTemplate);
      end
      else
        if InSmarty then
          Smarty := Smarty + Ch
        else
        	Output := Output + Ch;
    end;

    if InSmarty then
    	raise ESmartyException.CreateRes(@sBraceDoNotClose);
    if Output <> '' then AActions.Add(TRawOutputAction.CreateOutput(Self, Output));
    Result := '';
  end;

  procedure GetLinePosition(APosition: integer; var Line: integer; var Pos: integer);
  var
  	J: integer;
    Ch: char;
  begin
  	Line := 1;
    Pos := 1;
    J := 1;

    while (J <= Length(ADocument)) and (J <= APosition) do
    begin
      Ch := ADocument[J];
      Inc(J);
      if Ch = #13 then begin Inc(Line); Pos := 1; end
      else Inc(Pos);
    end;
  end;

var
	Str: string;
  I, L, P: integer;

begin
	Result := false;
	FCompiled := false;
  FActions.Clear;
	Errors.Clear;
  I := 1;

  try
  	Str := CompilePart(ADocument, FActions, naNone, I);
    if Str <> '' then
    	ESmartyException.CreateResFmt(@sInvalidTemplateDirective, [Str])
    else
    	FCompiled := true;
    Result := true;
  except
  	on E: ESmartyException do
    begin
    	GetLinePosition(I, L, P);
    	Errors.Add(E.Message + Format(sAtPosition, [L, P]));
    end;
  end;
end;

function TSmartyEngine.Execute: string;
var
  I: integer;
begin
	Result := '';
  if FCompiled then
	  for I := 0 to FActions.Count - 1 do
      Result := Result + FActions[I].Execute;
end;

function DateRecordToStr(Value: TDateRecord): string;
var
	Date: TDateTime;
  IsYear, IsMonth, IsDay: boolean;
  S: string;
begin
	IsYear := false;
  IsMonth := false;
  IsDay := false;
  if Value.Year = 0 then Value.Year := YearOf(Now) else IsYear := true;
  if Value.Month = 0 then Value.Month := 1 else IsMonth := true;
  if Value.Day = 0 then Value.Day := 1 else IsDay := true;
  if not IsYear and not IsMonth and not IsDay then Exit('');

  if TryEncodeDate(Value.Year, Value.Month, Value.Day, Date) then
  begin
    if IsYear and IsMonth and IsDay then
    	Result := DateToStr(Date)
    else begin
      S := FormatSettings.ShortDateFormat;
      if not IsYear then S := StringReplace(S, 'y', '', [rfReplaceAll, rfIgnoreCase]);
      if not IsMonth then S := StringReplace(S, 'm', '', [rfReplaceAll, rfIgnoreCase]);
			if not IsDay then S := StringReplace(S, 'd', '', [rfReplaceAll, rfIgnoreCase]);
      while (Length(S) > 0) and not CharInSet(S[1], ['D', 'M', 'Y', 'y', 'm', 'd']) do
      	Delete(S, 1, 1);
      while (Length(S) > 0) and not CharInSet(S[Length(S)], ['D', 'M', 'Y', 'y', 'm', 'd']) do
      	Delete(S, Length(S), 1);
      if Length(S) > 0 then
      	DateTimeToString(Result, S, Date)
      else
      	Result := '';
    end;
  end
  else
  	Result := '';
end;

function DateRecordToString(Value: TDateRecord): string;
begin
	Result := Format('%.4d-%.2d-%.2d', [Value.Year, Value.Month, Value.Day]);
end;

function StringToDateRecord(const Value: string): TDateRecord;
begin
  Result.Year := StrToInt(Copy(Value, 1, 4));
  Result.Month := StrToInt(Copy(Value, 6, 2));
  Result.Day := StrToInt(Copy(Value, 9, 2));
end;

function DateTimeFromRecord(Value: TDateRecord): TDateTime;
var
	Year, Month, Day: word;
begin
	if Value.Year = 0 then Year := YearOf(Now) else Year := Value.Year;
  if Value.Month = 0 then Month := 1 else Month := Value.Month;
  if Value.Day = 0 then Day := 1 else Day := Value.Day;
  if not TryEncodeDate(Year, Month, Day, Result) then Result := Date;
end;

function DateTimeToRecord(Value: TDateTime): TDateRecord;
var
	Year, Month, Day: word;
begin
	DecodeDate(Value, Year, Month, Day);
  Result.Year := Year;
  Result.Month := Month;
  Result.Day := Day;
end;

function IsEmpty(Value: TDateRecord): boolean;
begin
  Result := (Value.Year = 0) and (Value.Month = 0) and (Value.Day = 0);
end;

function GetStartDate(Value: TDateRecord): TDateTime;
begin
	if Value.Year > 0 then
  begin
  	if Value.Month = 0 then
    	Result := StartOfTheYear(Value.Year)
    else
    	if Value.Day = 0 then
      	Result := StartOfAMonth(Value.Year, Value.Month)
      else
      	Result := StartOfADay(Value.Year, Value.Month, Value.Day);
  end
  else
  	Result := StartOfTheYear(Now);
end;

function GetEndDate(Value: TDateRecord): TDateTime;
begin
  if Value.Year > 0 then
  begin
  	if Value.Month = 0 then
    	Result := EndOfTheYear(Value.Year)
    else
    	if Value.Day = 0 then
      	Result := EndOfAMonth(Value.Year, Value.Month)
      else
      	Result := EndOfADay(Value.Year, Value.Month, Value.Day);
  end
  else
  	Result := EndOfTheYear(Now);
end;

function DoValidIdent(const Value: string): string;
  function Alpha(C: Char): Boolean; inline;
  begin
    Result := TCharacter.IsLetter(C) or (C = '_');
  end;

  function AlphaNumeric(C: Char): Boolean; inline;
  begin
    Result := TCharacter.IsLetterOrDigit(C) or (C = '_');
  end;
var
	I: integer;
begin
	if (Value <> '') and not IsValidIdent(Value) then
  begin
  	I := 1;
    Result := '';

    while (I <= Length(Value)) do
    begin
    	if Alpha(Value[I]) then
      begin
      	Result := Value[I];
        Inc(I);
        Break;
      end
      else
      	Inc(I);
    end;

    while (I <= Length(Value)) do
    begin
    	if AlphaNumeric(Value[I]) then
      begin
      	Result := Result + Value[I];
        Inc(I);
      end
      else
      	Inc(I);
    end;
  end
  else
  	Result := Value;
end;

function GetFileContent(const AFilename: string; AEncoding: TEncoding): string;
var
  Stream: TFileStream;
  Size: integer;
  Buffer: TBytes;
  Encoding: TEncoding;
begin
  if FileExists(AFilename) then
  begin
    Stream := TFileStream.Create(AFilename, fmOpenRead or fmShareDenyWrite);
    try
      Size := Stream.Size;
      SetLength(Buffer, Size);
      Stream.Read(Buffer[0], Size);
      Encoding := nil;
      Size := TEncoding.GetBufferEncoding(Buffer, Encoding, AEncoding);
      Result := Encoding.GetString(Buffer, Size, Length(Buffer) - Size);
    finally
      Stream.Free;
    end;
  end
  else
    Result := '';
end;

{ TCustomClassList }

procedure TCustomClassList.Add(const AName: string; AClass: TClass);
var
  LClassRecord: TClassRecord;
begin
  LClassRecord := TClassRecord.Create;
  LClassRecord.FClass := AClass;
  AddObject(AName, LClassRecord);
end;

constructor TCustomClassList.Create;
begin
  inherited Create(True);
  CaseSensitive := False;
  Sorted := True;
end;

function TCustomClassList.GetClass(Index: Integer): TClass;
begin
  Result := TClassRecord(Objects[Index]).FClass;
end;

{ TModifierList }

procedure TModifierList.Add(AModifier: TVariableModifierClass);
var
  Name: string;
begin
  Name := AModifier.GetName;
  if IndexOf(Name) >= 0 then
    raise ESmartyException.CreateRes(@sDuplicateModifierName);
  inherited Add(Name, AModifier);
end;

function TModifierList.GetModifier(Index: Integer): TVariableModifierClass;
begin
  Result := TVariableModifierClass(GetClass(Index));
end;

{ TFunctionList }

procedure TFunctionList.Add(AFunction: TSmartyFunctionClass);
var
  Name: string;
begin
  Name := AFunction.GetName;
  if IndexOf(Name) >= 0 then
    raise ESmartyException.CreateRes(@sDuplicateFunctionName);
  inherited Add(Name, AFunction);
end;

function TFunctionList.GetFunction(Index: Integer): TSmartyFunctionClass;
begin
  Result := TSmartyFunctionClass(GetClass(Index));
end;

{ TNamespaceList }

procedure TNamespaceList.Add(ANamespace: TNamespaceProvider);
var
  Name: string;
begin
  Name := ANamespace.GetName;
  if IndexOf(Name) >= 0 then
    raise ESmartyException.CreateRes(@sDuplicateNamespaceName);
  AddObject(Name, ANamespace);
end;

initialization
	SmartyProvider := TSmartyInfoProvider.Create;

finalization
	SmartyProvider.Free;

end.
