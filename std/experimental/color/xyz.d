// Written in the D programming language.

/**
    This module implements XYZ and xyY _color types.

    Authors:    Manu Evans
    Copyright:  Copyright (c) 2015, Manu Evans.
    License:    $(WEB boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Source:     $(PHOBOSSRC std/experimental/color/xyz.d)
*/
module std.experimental.color.xyz;

import std.experimental.color;
version(unittest)
    import std.experimental.color.colorspace : WhitePoint;

import std.traits : isInstanceOf, isFloatingPoint;
import std.typetuple : TypeTuple;
import std.typecons : tuple;

@safe pure nothrow @nogc:


/**
Detect whether $(D T) is an XYZ color.
*/
enum isXYZ(T) = isInstanceOf!(XYZ, T);

///
unittest
{
    static assert(isXYZ!(XYZ!float) == true);
    static assert(isXYZ!(xyY!double) == false);
}


/**
Detect whether $(D T) is an xyY color.
*/
enum isxyY(T) = isInstanceOf!(xyY, T);

///
unittest
{
    static assert(isxyY!(xyY!float) == true);
    static assert(isxyY!(XYZ!double) == false);
}


/**
A CIE 1931 XYZ color, parameterised for component type.
*/
struct XYZ(F = float) if(isFloatingPoint!F)
{
@safe pure nothrow @nogc:

    /** Type of the color components. */
    alias ComponentType = F;

    /** X value. */
    F X = 0;
    /** Y value. */
    F Y = 0;
    /** Z value. */
    F Z = 0;

    /** Return the XYZ tristimulus values as a tuple. */
    @property auto tristimulus() const
    {
        return tuple(X, Y, Z);
    }

    /** Construct a color from XYZ values. */
    this(ComponentType X, ComponentType Y, ComponentType Z)
    {
        this.X = X;
        this.Y = Y;
        this.Z = Z;
    }

    /** Cast to other color types */
    Color opCast(Color)() const if(isColor!Color)
    {
        return convertColor!Color(this);
    }

    // operators
    mixin ColorOperators!(TypeTuple!("X","Y","Z"));


package:

    static To convertColorImpl(To, From)(From color) if(isXYZ!From && isXYZ!To)
    {
        alias F = To.ComponentType;
        return To(F(color.X), F(color.Y), F(color.Z));
    }
    unittest
    {
        static assert(convertColorImpl!(XYZ!float)(XYZ!double(1, 2, 3)) == XYZ!float(1, 2, 3));
        static assert(convertColorImpl!(XYZ!double)(XYZ!float(1, 2, 3)) == XYZ!double(1, 2, 3));
    }
}

///
unittest
{
    // CIE XYZ 1931 color with float components
    alias XYZf = XYZ!float;

    XYZf c = XYZf(0.8, 1, 1.2);

    // tristimulus() returns a tuple of the components
    assert(c.tristimulus == tuple(c.X, c.Y, c.Z));

    // test XYZ operators and functions
    static assert(XYZf(0, 0.5, 0) + XYZf(0.5, 0.5, 1) == XYZf(0.5, 1, 1));
    static assert(XYZf(0.5, 0.5, 1) * 100.0 == XYZf(50, 50, 100));
}


/**
A CIE 1931 xyY color, parameterised for component type.
*/
struct xyY(F = float) if(isFloatingPoint!F)
{
@safe pure nothrow @nogc:

    /** Type of the color components. */
    alias ComponentType = F;

    /** x coordinate. */
    F x = 0;
    /** y coordinate. */
    F y = 0;
    /** Y value (luminance). */
    F Y = 0;

    /** Construct a color from xyY values. */
    this(ComponentType x, ComponentType y, ComponentType Y)
    {
        this.x = x;
        this.y = y;
        this.Y = Y;
    }

    /** Cast to other color types */
    Color opCast(Color)() const if(isColor!Color)
    {
        return convertColor!Color(this);
    }

    // operators
    mixin ColorOperators!(TypeTuple!("x","y","Y"));


package:

    alias ParentColor = XYZ!ComponentType;

    static To convertColorImpl(To, From)(From color) if(isxyY!From && isxyY!To)
    {
        alias F = To.ComponentType;
        return To(F(color.x), F(color.y), F(color.Y));
    }
    unittest
    {
        static assert(convertColorImpl!(xyY!float)(xyY!double(1, 2, 3)) == xyY!float(1, 2, 3));
        static assert(convertColorImpl!(xyY!double)(xyY!float(1, 2, 3)) == xyY!double(1, 2, 3));
    }

    static To convertColorImpl(To, From)(From color) if(isxyY!From && isXYZ!To)
    {
        alias F = To.ComponentType;
        if(color.y == F(0))
            return To(F(0), F(0), F(0));
        else
            return To(F(color.x*color.Y/color.y), F(color.Y), F((F(1)-color.x-color.y)*color.Y/color.y));
    }
    unittest
    {
        static assert(convertColorImpl!(XYZ!float)(xyY!float(0.5, 0.5, 1)) == XYZ!float(1, 1, 0));

        // degenerate case
        static assert(convertColorImpl!(XYZ!float)(xyY!float(0.5, 0, 1)) == XYZ!float(0, 0, 0));
    }

    static To convertColorImpl(To, From)(From color) if(isXYZ!From && isxyY!To)
    {
        alias F = To.ComponentType;
        auto sum = color.X + color.Y + color.Z;
        if(sum == F(0))
            return To(WhitePoint!F.D65.x, WhitePoint!F.D65.y, F(0));
        else
            return To(F(color.X/sum), F(color.Y/sum), F(color.Y));
    }
    unittest
    {
        static assert(convertColorImpl!(xyY!float)(XYZ!float(0.5, 1, 0.5)) == xyY!float(0.25, 0.5, 1));

        // degenerate case
        static assert(convertColorImpl!(xyY!float)(XYZ!float(0, 0, 0)) == xyY!float(WhitePoint!float.D65.x, WhitePoint!float.D65.y, 0));
    }
}

///
unittest
{
    // CIE xyY 1931 color with double components
    alias xyYd = xyY!double;

    xyYd c = xyYd(0.4, 0.5, 1);

    // test xyY operators and functions
    static assert(xyYd(0, 0.5, 0) + xyYd(0.5, 0.5, 1) == xyYd(0.5, 1, 1));
    static assert(xyYd(0.5, 0.5, 1) * 100.0 == xyYd(50, 50, 100));
}
