/**
Easy API, for nicer D code. It replaces the FreeImage API, much like FreeImagePlug.

Copyright: Copyright Guillaume Piolat 2022
License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
*/
module gamut.easy;

import gamut.bitmap;
import gamut.general;
import gamut.types;
import gamut.memory;
import gamut.internals.cstring;

nothrow @nogc @safe:

/// Image type. Wraps FIBitmap.
struct Image
{
nothrow @nogc @safe:
public:

    ~this()
    {
        cleanupBitmapIfAny();
    }

    /// Load an image from a file location.
    /// Returns: true if successfull.
    bool loadFromFile(const(char)[] path, int flags = 0) @trusted
    {
        initializeFreeImageLazilyIfFirstCall();
        cleanupBitmapIfAny();

        CString cstr = CString(path);
        
        // TODO: scan type
        _bitmap = FreeImage_Load(FIF_JPEG, cstr.storage, flags);

        // TODO: deal with failure

        return _bitmap !is null;
    }

    /// Load an image from a memory location.
    /// Returns: true if successfull.
    bool loadFromMemory(const(ubyte)[] bytes, int flags = 0) @trusted
    {
        initializeFreeImageLazilyIfFirstCall();
        cleanupBitmapIfAny();

        // PERF: a way to have FIMEMORY in a local instead of heap.
        FIMEMORY* stream = FreeImage_OpenMemory(bytes.ptr, bytes.length);
        scope(exit) FreeImage_CloseMemory(stream);

        // TODO: scan type
        _bitmap = FreeImage_LoadFromMemory(FIF_JPEG, stream, flags);

        // TODO: deal with failure here

        return _bitmap !is null;
    }
    ///ditto
    bool loadFromMemory(const(void)[] bytes, int flags = 0) @trusted
    {
        return loadFromMemory(cast(const(ubyte)[])bytes, flags);
    }

    /// Returns: Width of image in pixels.
    int width() pure
    {
        assert(_bitmap !is null);
        return FreeImage_GetWidth(_bitmap);
    }

    /// Returns: Height of image in pixels.
    int height() pure
    {
        assert(_bitmap !is null);
        return FreeImage_GetHeight(_bitmap);
    }

private:
    FIBITMAP* _bitmap;

    void cleanupBitmapIfAny() @trusted
    {
        if (_bitmap !is null)
        {
            FreeImage_Unload(_bitmap);
            _bitmap = null;
        }
    }

    void initializeFreeImageLazilyIfFirstCall()
    {
        // Lazy-initialize the library if not done already.
        FreeImage_Initialise(false);
    }
}