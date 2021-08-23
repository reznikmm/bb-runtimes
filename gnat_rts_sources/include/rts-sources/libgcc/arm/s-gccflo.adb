------------------------------------------------------------------------------
--                                                                          --
--                         GNAT COMPILER COMPONENTS                         --
--                                                                          --
--                    S Y S T E M . G C C . F L O A T S                     --
--                                                                          --
--                                 B o d y                                  --
--                                                                          --
--         Copyright (C) 2017-2020, Free Software Foundation, Inc.          --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
-- As a special exception under Section 7 of GPL version 3, you are granted --
-- additional permissions described in the GCC Runtime Library Exception,   --
-- version 3.1, as published by the Free Software Foundation.               --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

--  Ada implementation of libgcc: 64-bit double conversions
pragma Restrictions (No_Elaboration_Code);

package body System.GCC.Floats is
   pragma Annotate (Gnatcheck, Exempt_On, "Improper_Returns",
                    "better readability with multiple returns");

   use Interfaces;

   function "-" (V : AEABI_F32) return AEABI_F32
     is (Conv (-Conv (V)));

   function "-" (V : AEABI_F64) return AEABI_F64
     is (Conv (-Conv (V)));

   function Floatdisf (V : Integer_64) return AEABI_F32 is
   begin
      if V < 0 then
         return -Floatundisf (Unsigned_64 (-V));
      else
         return Floatundisf (Unsigned_64 (V));
      end if;
   end Floatdisf;

   function Floatundisf (V : Unsigned_64) return AEABI_F32 is
      Res_Hi, Res_Mid, Res_Lo : Unsigned_32;
      Res : Float32;
   begin
      --  Assume IEEE 754 Float32 format

      --  Set Res_Lo to 2.0**23. The nice property is that the LSB of that
      --  value represents 1, the next bit 2 etc. So adding Res_Lo with an
      --  integer can be done using integer addition.
      Res_Lo := 16#4b000000#;

      --  So add the lowest 22 bit of V
      Res_Lo := Res_Lo or Unsigned_32 (V and 16#3f_ffff#);

      --  Set Res_Mid to 2.0**45, whose LSB represents 2**22.
      Res_Mid := 16#56000000#;
      Res_Mid := Res_Mid or Unsigned_32 (Shift_Right (V, 22) and 16#3f_ffff#);

      --  Set Res_Hi to 2.0**67, whose LSB represents 2**44.
      Res_Hi := 16#61000000#;
      Res_Hi := Res_Hi or Unsigned_32 (Shift_Right (V, 44) and 16#0f_ffff#);

      --  Substract implicit ones
      Res := To_Float32 (Res_Hi) - 2.0**67 - 2.0**45;
      Res := Res + To_Float32 (Res_Mid) - 2.0**23;
      Res := Res + To_Float32 (Res_Lo);

      return Conv (Res);
   end Floatundisf;

   function Floatdidf (V : Integer_64) return AEABI_F64 is
   begin
      if V < 0 then
         return -Floatundidf (Unsigned_64 (-V));
      else
         return Floatundidf (Unsigned_64 (V));
      end if;
   end Floatdidf;

   function Floatundidf (V : Unsigned_64) return AEABI_F64 is
      Res_Hi, Res_Lo : Unsigned_64;
      Res : Float64;
   begin
      --  Assume IEEE 754 Float64 format

      --  Set Res_Lo to 2.0**52. The nice property is that the LSB of that
      --  value represents 1, the next bit 2 etc. So adding Res_Lo with an
      --  integer can be done using integer addition.
      Res_Lo := 16#433_0000000000000#;

      --  So add the lowest part of V.
      Res_Lo := Res_Lo or (V and 16#ffff_ffff#);

      --  Set Res_Hi to 2.0**84, whose LSB represents 2**32.
      Res_Hi := 16#453_0000000000000#;
      Res_Hi := Res_Hi or Shift_Right (V, 32);

      --  Substract the extract implicit bits
      Res := To_Float64 (Res_Hi) - 2.0**84 - 2.0**52;

      --  Lets the addition do the rounding
      Res := Res + To_Float64 (Res_Lo);

      return Conv (Res);
   end Floatundidf;

   function Fixsfdi (V : AEABI_F32) return Integer_64
   is
   begin
      if Conv (V) < 0.0 then
         return -Integer_64 (Fixunssfdi (-V));
      else
         return Integer_64 (Fixunssfdi (V));
      end if;
   end Fixsfdi;

   function Fixunssfdi (V : AEABI_F32) return Unsigned_64
   is
      --  Use Float64 representation as it provides more than 32 bit of
      --  mantissa.
      Dv     : constant Float64 := Float64 (Conv (V));
      Hi, Lo : Unsigned_32;
   begin
      if Dv <= 0.0 then
         return 0;
      end if;

      Hi := Unsigned_32 (Float64'Truncation (Dv / 2.0**32));
      Lo := Unsigned_32 (Float64'Truncation (Dv - Float64 (Hi) * 2.0**32));
      return Merge (Hi, Lo);
   end Fixunssfdi;

   function Fixdfdi (V : AEABI_F64) return Integer_64 is
   begin
      if Conv (V) < 0.0 then
         return -Integer_64 (Fixunsdfdi (-V));
      else
         return Integer_64 (Fixunsdfdi (V));
      end if;
   end Fixdfdi;

   function Fixunsdfdi (V : AEABI_F64) return Unsigned_64
   is
      Dv     : constant Float64 := Conv (V);
      Hi, Lo : Unsigned_32;
   begin
      if Dv <= 0.0 then
         return 0;
      end if;

      Hi := Unsigned_32 (Float64'Truncation (Dv / 2.0**32));
      Lo := Unsigned_32 (Float64'Truncation (Dv - Float64 (Hi) * 2.0**32));
      return Merge (Hi, Lo);
   end Fixunsdfdi;

   pragma Annotate (Gnatcheck, Exempt_Off, "Improper_Returns");
end System.GCC.Floats;
