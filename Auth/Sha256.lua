-- Auth/Sha256.lua
-- Pure Luau SHA-256 (needed by providers that hash identifiers). Uses the bit32 library.

local Sha256 = {}

local band, bxor, bnot, rshift, rrotate = bit32.band, bit32.bxor, bit32.bnot, bit32.rshift, bit32.rrotate

local roundConstants = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

local initialHash = {
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
}

-- Returns the lowercase hex digest of the message
function Sha256.hash(message)
    message = tostring(message)
    local length = #message
    local padded = message .. "\128" .. string.rep("\0", (55 - length) % 64) .. string.pack(">I8", length * 8)

    local h0, h1, h2, h3, h4, h5, h6, h7 = table.unpack(initialHash)
    local words = {}

    for chunkStart = 1, #padded, 64 do
        for index = 1, 16 do
            words[index] = (string.unpack(">I4", padded, chunkStart + (index - 1) * 4))
        end
        for index = 17, 64 do
            local previous15, previous2 = words[index - 15], words[index - 2]
            local sigma0 = bxor(rrotate(previous15, 7), rrotate(previous15, 18), rshift(previous15, 3))
            local sigma1 = bxor(rrotate(previous2, 17), rrotate(previous2, 19), rshift(previous2, 10))
            words[index] = band(words[index - 16] + sigma0 + words[index - 7] + sigma1, 0xFFFFFFFF)
        end

        local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7

        for index = 1, 64 do
            local sum1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
            local choice = bxor(band(e, f), band(bnot(e), g))
            local temp1 = band(h + sum1 + choice + roundConstants[index] + words[index], 0xFFFFFFFF)
            local sum0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
            local majority = bxor(band(a, b), band(a, c), band(b, c))
            local temp2 = band(sum0 + majority, 0xFFFFFFFF)

            h = g
            g = f
            f = e
            e = band(d + temp1, 0xFFFFFFFF)
            d = c
            c = b
            b = a
            a = band(temp1 + temp2, 0xFFFFFFFF)
        end

        h0 = band(h0 + a, 0xFFFFFFFF)
        h1 = band(h1 + b, 0xFFFFFFFF)
        h2 = band(h2 + c, 0xFFFFFFFF)
        h3 = band(h3 + d, 0xFFFFFFFF)
        h4 = band(h4 + e, 0xFFFFFFFF)
        h5 = band(h5 + f, 0xFFFFFFFF)
        h6 = band(h6 + g, 0xFFFFFFFF)
        h7 = band(h7 + h, 0xFFFFFFFF)
    end

    return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
end

return Sha256

