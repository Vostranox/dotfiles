import QtQuick

QtObject {
    id: nav

    property Item container
    property int  index: -1

    function collect(item, out) {
        for (const c of item.children) {
            if (!c || c.visible === false) continue;
            if (c.navigable === true) out.push(c);
            else if (c.children) nav.collect(c, out);
        }
    }
    function list() {
        const out = [];
        if (nav.container) nav.collect(nav.container, out);
        out.sort((a, b) => {
            const pa = a.mapToItem(nav.container, 0, 0), pb = b.mapToItem(nav.container, 0, 0);
            return Math.abs(pa.y - pb.y) > 1 ? pa.y - pb.y : pa.x - pb.x;
        });
        return out;
    }
    function apply(l)  { for (let i = 0; i < l.length; i++) l[i].navSelected = (i === nav.index); }
    function step(d) {
        const l = nav.list();
        if (!l.length) return;
        nav.index = nav.index < 0 ? (d > 0 ? 0 : l.length - 1)
                                  : (nav.index + d + l.length) % l.length;
        nav.apply(l);
    }
    function current() {
        const l = nav.list();
        return (nav.index >= 0 && nav.index < l.length) ? l[nav.index] : null;
    }
    function reset() { nav.index = -1; nav.apply(nav.list()); }
}
