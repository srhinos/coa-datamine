"""3.3.5a itemcache.wdb parser (SMSG_ITEM_QUERY_SINGLE_RESPONSE cache).

Copied from coa-sim-handoff/parsers/wdb_item.py (task W4-11b, per
DATAMINE-REQUEST.md Sec 12's "working itemcache.wdb parser... 17,531 records, 0
failures" attribution) as the independent ground truth for the ItemStat.dbc
f1=itemId/f2=ownItemLevel golden check (tools/dbc.py's ItemStat TABLE_MAPS
comment, tests/test_items_layer.py section (b)). Verbatim decode logic; only the
unused `json`/`collections` imports from the original throwaway script were
dropped - no behavioral change.

Field order per TrinityCore 3.3.5 WorldSession::HandleItemQuerySingleOpcode.
Validation strategy: each record block has a declared size; we require the
reader to land EXACTLY on the block end. Any mismatch is reported, not hidden.
"""
import struct, sys

HDR = 24

class R:
    __slots__ = ('b', 'o')
    def __init__(self, b, o=0):
        self.b = b; self.o = o
    def u32(self):
        v = struct.unpack_from('<I', self.b, self.o)[0]; self.o += 4; return v
    def i32(self):
        v = struct.unpack_from('<i', self.b, self.o)[0]; self.o += 4; return v
    def f32(self):
        v = struct.unpack_from('<f', self.b, self.o)[0]; self.o += 4; return v
    def cstr(self):
        e = self.b.index(b'\0', self.o)
        s = self.b[self.o:e]; self.o = e + 1
        return s.decode('utf-8', 'replace')

def parse_block(entry, blk):
    r = R(blk)
    it = {'entry': entry}
    it['class'] = r.u32()
    it['subclass'] = r.u32()
    it['soundOverrideSubclass'] = r.i32()
    it['name'] = r.cstr()
    r.cstr(); r.cstr(); r.cstr()          # name2..4 (always empty from server)
    it['displayId'] = r.u32()
    it['quality'] = r.u32()
    it['flags'] = r.u32()
    it['flags2'] = r.u32()
    it['buyPrice'] = r.u32()
    it['sellPrice'] = r.u32()
    it['inventoryType'] = r.u32()
    it['allowableClass'] = r.i32()
    it['allowableRace'] = r.i32()
    it['itemLevel'] = r.u32()
    it['requiredLevel'] = r.u32()
    it['requiredSkill'] = r.u32()
    it['requiredSkillRank'] = r.u32()
    it['requiredSpell'] = r.u32()
    it['requiredHonorRank'] = r.u32()
    it['requiredCityRank'] = r.u32()
    it['requiredRepFaction'] = r.u32()
    it['requiredRepRank'] = r.u32()
    it['maxCount'] = r.i32()
    it['stackable'] = r.i32()
    it['containerSlots'] = r.u32()
    n = r.u32()
    it['statsCount'] = n
    if n > 32:
        raise ValueError('statsCount=%d insane' % n)
    stats = []
    for _ in range(n):
        st = r.u32(); sv = r.i32()
        stats.append((st, sv))
    it['stats'] = stats
    it['scalingStatDistribution'] = r.u32()
    it['scalingStatValue'] = r.u32()
    dmg = []
    for _ in range(2):
        dmin = r.f32(); dmax = r.f32(); dtype = r.u32()
        dmg.append((dmin, dmax, dtype))
    it['damage'] = dmg
    it['armor'] = r.u32()
    it['resist'] = [r.u32() for _ in range(6)]   # holy fire nature frost shadow arcane
    it['delay'] = r.u32()
    it['ammoType'] = r.u32()
    it['rangedModRange'] = r.f32()
    spells = []
    for _ in range(5):
        sid = r.i32(); trig = r.u32(); chg = r.i32(); cd = r.i32()
        cat = r.u32(); catcd = r.i32()
        spells.append((sid, trig, chg, cd, cat, catcd))
    it['spells'] = spells
    it['bonding'] = r.u32()
    it['description'] = r.cstr()
    it['pageText'] = r.u32()
    it['languageId'] = r.u32()
    it['pageMaterial'] = r.u32()
    it['startQuest'] = r.u32()
    it['lockId'] = r.u32()
    it['material'] = r.i32()
    it['sheath'] = r.u32()
    it['randomProperty'] = r.u32()
    it['randomSuffix'] = r.u32()
    it['block'] = r.u32()
    it['itemSet'] = r.u32()
    it['maxDurability'] = r.u32()
    it['area'] = r.u32()
    it['map'] = r.i32()
    it['bagFamily'] = r.u32()
    it['totemCategory'] = r.u32()
    it['sockets'] = [(r.u32(), r.u32()) for _ in range(3)]
    it['socketBonus'] = r.u32()
    it['gemProperties'] = r.u32()
    it['requiredDisenchantSkill'] = r.i32()
    it['armorDamageModifier'] = r.f32()
    it['duration'] = r.u32()
    it['itemLimitCategory'] = r.u32()
    it['holidayId'] = r.u32()
    it['_consumed'] = r.o
    return it

def parse_file(path):
    b = open(path, 'rb').read()
    assert b[:4] == b'BDIW', b[:4]
    build = struct.unpack_from('<I', b, 4)[0]
    off = HDR
    items, bad, term = [], [], None
    n = len(b)
    while off + 8 <= n:
        entry, size = struct.unpack_from('<II', b, off)
        if entry == 0 and size == 0:
            term = off; break
        off += 8
        blk = b[off:off + size]
        if len(blk) < size:
            bad.append((entry, size, 'truncated at EOF')); break
        try:
            it = parse_block(entry, blk)
            if it['_consumed'] != size:
                bad.append((entry, size, 'consumed %d != %d (delta %+d)'
                            % (it['_consumed'], size, it['_consumed'] - size)))
            else:
                items.append(it)
        except Exception as e:
            bad.append((entry, size, '%s: %s' % (type(e).__name__, e)))
        off += size
    return build, items, bad, term, n

if __name__ == '__main__':
    path = sys.argv[1]
    build, items, bad, term, n = parse_file(path)
    print('file       :', path)
    print('size       :', n, 'bytes | build', build)
    print('terminator :', term, '(EOF at %d)' % n)
    print('parsed OK  :', len(items))
    print('failed     :', len(bad))
    for e, s, m in bad[:15]:
        print('   entry %-8d size %-6d %s' % (e, s, m))
