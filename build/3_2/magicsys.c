/* Generated by Nimrod Compiler v0.8.10 */
/*   (c) 2010 Andreas Rumpf */

typedef long long int NI;
typedef unsigned long long int NU;
#include "nimbase.h"

typedef struct TY55547 TY55547;
typedef struct TY55551 TY55551;
typedef struct TY55529 TY55529;
typedef struct TNimType TNimType;
typedef struct TNimNode TNimNode;
typedef struct TY55527 TY55527;
typedef struct TGenericSeq TGenericSeq;
typedef struct NimStringDesc NimStringDesc;
typedef struct TY54011 TY54011;
typedef struct TY54005 TY54005;
typedef struct TNimObject TNimObject;
typedef struct TY47532 TY47532;
typedef struct TY55525 TY55525;
typedef struct TY55539 TY55539;
typedef struct TY52008 TY52008;
typedef struct TY55543 TY55543;
typedef struct TY55549 TY55549;
typedef struct TY10802 TY10802;
typedef struct TY10814 TY10814;
typedef struct TY11190 TY11190;
typedef struct TY10818 TY10818;
typedef struct TY10810 TY10810;
typedef struct TY11188 TY11188;
typedef struct TY59107 TY59107;
typedef struct TY55519 TY55519;
typedef struct TY43013 TY43013;
typedef struct TY59109 TY59109;
typedef TY55551* TY101027[40];
struct TNimType {
NI size;
NU8 kind;
NU8 flags;
TNimType* base;
TNimNode* node;
void* finalizer;
};
struct TGenericSeq {
NI len;
NI space;
};
struct TY55529 {
TNimType* m_type;
NI Counter;
TY55527* Data;
};
struct TNimNode {
NU8 kind;
NI offset;
TNimType* typ;
NCSTRING name;
NI len;
TNimNode** sons;
};
typedef NIM_CHAR TY239[100000001];
struct NimStringDesc {
  TGenericSeq Sup;
TY239 data;
};
struct TNimObject {
TNimType* m_type;
};
struct TY54005 {
  TNimObject Sup;
NI Id;
};
struct TY47532 {
NI16 Line;
NI16 Col;
int Fileindex;
};
struct TY55539 {
NU8 K;
NU8 S;
NU8 Flags;
TY55551* T;
TY52008* R;
NI A;
};
struct TY55547 {
  TY54005 Sup;
NU8 Kind;
NU8 Magic;
TY55551* Typ;
TY54011* Name;
TY47532 Info;
TY55547* Owner;
NU32 Flags;
TY55529 Tab;
TY55525* Ast;
NU32 Options;
NI Position;
NI Offset;
TY55539 Loc;
TY55543* Annex;
};
struct TY55551 {
  TY54005 Sup;
NU8 Kind;
TY55549* Sons;
TY55525* N;
NU8 Flags;
NU8 Callconv;
TY55547* Owner;
TY55547* Sym;
NI64 Size;
NI Align;
NI Containerid;
TY55539 Loc;
};
struct TY10802 {
NI Refcount;
TNimType* Typ;
};
struct TY10818 {
NI Len;
NI Cap;
TY10802** D;
};
struct TY10814 {
NI Counter;
NI Max;
TY10810* Head;
TY10810** Data;
};
struct TY11188 {
NI Stackscans;
NI Cyclecollections;
NI Maxthreshold;
NI Maxstacksize;
NI Maxstackcells;
NI Cycletablesize;
};
struct TY11190 {
TY10818 Zct;
TY10818 Decstack;
TY10814 Cycleroots;
TY10818 Tempstack;
NI Cyclerootslock;
NI Zctlock;
TY11188 Stat;
};
struct TY54011 {
  TY54005 Sup;
NimStringDesc* S;
TY54011* Next;
NI H;
};
struct TY55525 {
TY55551* Typ;
NimStringDesc* Comment;
TY47532 Info;
NU8 Flags;
NU8 Kind;
union {
struct {NI64 Intval;
} S1;
struct {NF64 Floatval;
} S2;
struct {NimStringDesc* Strval;
} S3;
struct {TY55547* Sym;
} S4;
struct {TY54011* Ident;
} S5;
struct {TY55519* Sons;
} S6;
} KindU;
};
struct TY52008 {
  TNimObject Sup;
TY52008* Left;
TY52008* Right;
NI Length;
NimStringDesc* Data;
};
struct TY43013 {
  TNimObject Sup;
TY43013* Prev;
TY43013* Next;
};
struct TY55543 {
  TY43013 Sup;
NU8 Kind;
NIM_BOOL Generated;
TY52008* Name;
TY55525* Path;
};
typedef NI TY8814[8];
struct TY10810 {
TY10810* Next;
NI Key;
TY8814 Bits;
};
struct TY59107 {
NI Tos;
TY59109* Stack;
};
struct TY55527 {
  TGenericSeq Sup;
  TY55547* data[SEQ_DECL_SIZE];
};
struct TY55549 {
  TGenericSeq Sup;
  TY55551* data[SEQ_DECL_SIZE];
};
struct TY55519 {
  TGenericSeq Sup;
  TY55525* data[SEQ_DECL_SIZE];
};
struct TY59109 {
  TGenericSeq Sup;
  TY55529 data[SEQ_DECL_SIZE];
};
N_NIMCALL(void, Initstrtable_55746)(TY55529* X_55749);
N_NIMCALL(TY55551*, Systypefromname_101073)(NimStringDesc* Name_101075);
N_NIMCALL(TY55547*, Getsyssym_101024)(NimStringDesc* Name_101026);
N_NIMCALL(TY55547*, Strtableget_59069)(TY55529* T_59071, TY54011* Name_59072);
N_NIMCALL(TY54011*, Getident_54016)(NimStringDesc* Identifier_54018);
N_NIMCALL(void, Rawmessage_47553)(NU8 Msg_47555, NimStringDesc* Arg_47556);
N_NIMCALL(void, Loadstub_92070)(TY55547* S_92072);
N_NIMCALL(TY55551*, Newsystype_101044)(NU8 Kind_101046, NI Size_101047);
N_NIMCALL(TY55551*, Newtype_55706)(NU8 Kind_55708, TY55547* Owner_55709);
N_NIMCALL(void, Internalerror_47571)(NimStringDesc* Errmsg_47573);
static N_INLINE(void, appendString)(NimStringDesc* Dest_18792, NimStringDesc* Src_18793);
N_NIMCALL(NimStringDesc*, reprEnum)(NI E_19779, TNimType* Typ_19780);
N_NIMCALL(NimStringDesc*, rawNewString)(NI Space_18687);
static N_INLINE(void, asgnRef)(void** Dest_13214, void* Src_13215);
static N_INLINE(void, Incref_13202)(TY10802* C_13204);
static N_INLINE(NI, Atomicinc_3001)(NI* Memloc_3004, NI X_3005);
static N_INLINE(NIM_BOOL, Canbecycleroot_11616)(TY10802* C_11618);
static N_INLINE(void, Rtladdcycleroot_12252)(TY10802* C_12254);
N_NOINLINE(void, Incl_11074)(TY10814* S_11077, TY10802* Cell_11078);
static N_INLINE(TY10802*, Usrtocell_11612)(void* Usr_11614);
static N_INLINE(void, Decref_13001)(TY10802* C_13003);
static N_INLINE(NI, Atomicdec_3006)(NI* Memloc_3009, NI X_3010);
static N_INLINE(void, Rtladdzct_12601)(TY10802* C_12603);
N_NOINLINE(void, Addzct_11601)(TY10818* S_11604, TY10802* C_11605);
N_NIMCALL(void, Strtableadd_59064)(TY55529* T_59067, TY55547* N_59068);
N_NIMCALL(TY54011*, Getident_54019)(NimStringDesc* Identifier_54021, NI H_54022);
N_NIMCALL(NI, Getnormalizedhash_44037)(NimStringDesc* S_44039);
STRING_LITERAL(TMP196985, "int", 3);
STRING_LITERAL(TMP196986, "int8", 4);
STRING_LITERAL(TMP196987, "int16", 5);
STRING_LITERAL(TMP196988, "int32", 5);
STRING_LITERAL(TMP196989, "int64", 5);
STRING_LITERAL(TMP196990, "float", 5);
STRING_LITERAL(TMP196991, "float32", 7);
STRING_LITERAL(TMP196992, "float64", 7);
STRING_LITERAL(TMP196993, "bool", 4);
STRING_LITERAL(TMP196994, "char", 4);
STRING_LITERAL(TMP196995, "string", 6);
STRING_LITERAL(TMP196996, "cstring", 7);
STRING_LITERAL(TMP196997, "pointer", 7);
STRING_LITERAL(TMP196998, "request for typekind: ", 22);
STRING_LITERAL(TMP196999, "wanted: ", 8);
STRING_LITERAL(TMP197000, " got: ", 6);
STRING_LITERAL(TMP197001, "type not found: ", 16);
TY55547* Systemmodule_101004;
TY101027 Gsystypes_101028;
TY55529 Compilerprocs_101029;
extern TNimType* NTI55529; /* TStrTable */
extern NI Ptrsize_51572;
extern TNimType* NTI55162; /* TTypeKind */
extern TY11190 Gch_11210;
extern TY55529 Rodcompilerprocs_92059;
N_NIMCALL(TY55547*, Getsyssym_101024)(NimStringDesc* Name_101026) {
TY55547* Result_101052;
TY54011* LOC1;
Result_101052 = 0;
LOC1 = 0;
LOC1 = Getident_54016(Name_101026);
Result_101052 = Strtableget_59069(&(*Systemmodule_101004).Tab, LOC1);
if (!(Result_101052 == NIM_NIL)) goto LA3;
Rawmessage_47553(((NU8) 61), Name_101026);
LA3: ;
if (!((*Result_101052).Kind == ((NU8) 20))) goto LA6;
Loadstub_92070(Result_101052);
LA6: ;
return Result_101052;
}
N_NIMCALL(TY55551*, Systypefromname_101073)(NimStringDesc* Name_101075) {
TY55551* Result_101076;
TY55547* LOC1;
Result_101076 = 0;
LOC1 = 0;
LOC1 = Getsyssym_101024(Name_101075);
Result_101076 = (*LOC1).Typ;
return Result_101076;
}
N_NIMCALL(TY55551*, Newsystype_101044)(NU8 Kind_101046, NI Size_101047) {
TY55551* Result_101048;
Result_101048 = 0;
Result_101048 = Newtype_55706(Kind_101046, Systemmodule_101004);
(*Result_101048).Size = ((NI64) (Size_101047));
(*Result_101048).Align = Size_101047;
return Result_101048;
}
static N_INLINE(void, appendString)(NimStringDesc* Dest_18792, NimStringDesc* Src_18793) {
memcpy(((NCSTRING) (&(*Dest_18792).data[((*Dest_18792).Sup.len)-0])), ((NCSTRING) ((*Src_18793).data)), ((int) ((NI64)((NI64)((*Src_18793).Sup.len + 1) * 1))));
(*Dest_18792).Sup.len += (*Src_18793).Sup.len;
}
static N_INLINE(NI, Atomicinc_3001)(NI* Memloc_3004, NI X_3005) {
NI Result_7607;
Result_7607 = 0;
(*Memloc_3004) += X_3005;
Result_7607 = (*Memloc_3004);
return Result_7607;
}
static N_INLINE(NIM_BOOL, Canbecycleroot_11616)(TY10802* C_11618) {
NIM_BOOL Result_11619;
Result_11619 = 0;
Result_11619 = !((((*(*C_11618).Typ).flags &(1<<((((NU8) 1))&7)))!=0));
return Result_11619;
}
static N_INLINE(void, Rtladdcycleroot_12252)(TY10802* C_12254) {
Incl_11074(&Gch_11210.Cycleroots, C_12254);
}
static N_INLINE(void, Incref_13202)(TY10802* C_13204) {
NI LOC1;
NIM_BOOL LOC3;
LOC1 = Atomicinc_3001(&(*C_13204).Refcount, 8);
LOC3 = Canbecycleroot_11616(C_13204);
if (!LOC3) goto LA4;
Rtladdcycleroot_12252(C_13204);
LA4: ;
}
static N_INLINE(TY10802*, Usrtocell_11612)(void* Usr_11614) {
TY10802* Result_11615;
Result_11615 = 0;
Result_11615 = ((TY10802*) ((NI64)((NU64)(((NI) (Usr_11614))) - (NU64)(((NI) (((NI)sizeof(TY10802))))))));
return Result_11615;
}
static N_INLINE(NI, Atomicdec_3006)(NI* Memloc_3009, NI X_3010) {
NI Result_7806;
Result_7806 = 0;
(*Memloc_3009) -= X_3010;
Result_7806 = (*Memloc_3009);
return Result_7806;
}
static N_INLINE(void, Rtladdzct_12601)(TY10802* C_12603) {
Addzct_11601(&Gch_11210.Zct, C_12603);
}
static N_INLINE(void, Decref_13001)(TY10802* C_13003) {
NI LOC2;
NIM_BOOL LOC5;
LOC2 = Atomicdec_3006(&(*C_13003).Refcount, 8);
if (!((NU64)(LOC2) < (NU64)(8))) goto LA3;
Rtladdzct_12601(C_13003);
goto LA1;
LA3: ;
LOC5 = Canbecycleroot_11616(C_13003);
if (!LOC5) goto LA6;
Rtladdcycleroot_12252(C_13003);
goto LA1;
LA6: ;
LA1: ;
}
static N_INLINE(void, asgnRef)(void** Dest_13214, void* Src_13215) {
TY10802* LOC4;
TY10802* LOC8;
if (!!((Src_13215 == NIM_NIL))) goto LA2;
LOC4 = Usrtocell_11612(Src_13215);
Incref_13202(LOC4);
LA2: ;
if (!!(((*Dest_13214) == NIM_NIL))) goto LA6;
LOC8 = Usrtocell_11612((*Dest_13214));
Decref_13001(LOC8);
LA6: ;
(*Dest_13214) = Src_13215;
}
N_NIMCALL(TY55551*, Getsystype_101008)(NU8 Kind_101010) {
TY55551* Result_101080;
NimStringDesc* LOC4;
NimStringDesc* LOC8;
NimStringDesc* LOC12;
Result_101080 = 0;
Result_101080 = Gsystypes_101028[(Kind_101010)-0];
if (!(Result_101080 == NIM_NIL)) goto LA2;
switch (Kind_101010) {
case ((NU8) 31):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196985));
break;
case ((NU8) 32):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196986));
break;
case ((NU8) 33):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196987));
break;
case ((NU8) 34):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196988));
break;
case ((NU8) 35):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196989));
break;
case ((NU8) 36):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196990));
break;
case ((NU8) 37):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196991));
break;
case ((NU8) 38):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196992));
break;
case ((NU8) 1):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196993));
break;
case ((NU8) 2):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196994));
break;
case ((NU8) 28):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196995));
break;
case ((NU8) 29):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196996));
break;
case ((NU8) 26):
Result_101080 = Systypefromname_101073(((NimStringDesc*) &TMP196997));
break;
case ((NU8) 5):
Result_101080 = Newsystype_101044(((NU8) 5), Ptrsize_51572);
break;
default:
LOC4 = 0;
LOC4 = rawNewString(reprEnum(Kind_101010, NTI55162)->Sup.len + 22);
appendString(LOC4, ((NimStringDesc*) &TMP196998));
appendString(LOC4, reprEnum(Kind_101010, NTI55162));
Internalerror_47571(LOC4);
break;
}
asgnRef((void**) &Gsystypes_101028[(Kind_101010)-0], Result_101080);
LA2: ;
if (!!(((*Result_101080).Kind == Kind_101010))) goto LA6;
LOC8 = 0;
LOC8 = rawNewString(reprEnum(Kind_101010, NTI55162)->Sup.len + reprEnum((*Result_101080).Kind, NTI55162)->Sup.len + 14);
appendString(LOC8, ((NimStringDesc*) &TMP196999));
appendString(LOC8, reprEnum(Kind_101010, NTI55162));
appendString(LOC8, ((NimStringDesc*) &TMP197000));
appendString(LOC8, reprEnum((*Result_101080).Kind, NTI55162));
Internalerror_47571(LOC8);
LA6: ;
if (!(Result_101080 == NIM_NIL)) goto LA10;
LOC12 = 0;
LOC12 = rawNewString(reprEnum(Kind_101010, NTI55162)->Sup.len + 16);
appendString(LOC12, ((NimStringDesc*) &TMP197001));
appendString(LOC12, reprEnum(Kind_101010, NTI55162));
Internalerror_47571(LOC12);
LA10: ;
return Result_101080;
}
N_NIMCALL(void, Registercompilerproc_101014)(TY55547* S_101016) {
Strtableadd_59064(&Compilerprocs_101029, S_101016);
}
N_NIMCALL(void, Initsystem_101017)(TY59107* Tab_101020) {
}
N_NIMCALL(TY55547*, Getcompilerproc_101011)(NimStringDesc* Name_101013) {
TY55547* Result_101187;
TY54011* Ident_101188;
NI LOC1;
Result_101187 = 0;
Ident_101188 = 0;
LOC1 = Getnormalizedhash_44037(Name_101013);
Ident_101188 = Getident_54019(Name_101013, LOC1);
Result_101187 = Strtableget_59069(&Compilerprocs_101029, Ident_101188);
if (!(Result_101187 == NIM_NIL)) goto LA3;
Result_101187 = Strtableget_59069(&Rodcompilerprocs_92059, Ident_101188);
if (!!((Result_101187 == NIM_NIL))) goto LA6;
Strtableadd_59064(&Compilerprocs_101029, Result_101187);
if (!((*Result_101187).Kind == ((NU8) 20))) goto LA9;
Loadstub_92070(Result_101187);
LA9: ;
LA6: ;
LA3: ;
return Result_101187;
}
N_NOINLINE(void, magicsysInit)(void) {
Compilerprocs_101029.m_type = NTI55529;
Initstrtable_55746(&Compilerprocs_101029);
}
