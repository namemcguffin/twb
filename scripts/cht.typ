// content hash test

// assess number of collisions yielded by adapted FNV-1a hash function used for cache busting logic
// uses as input data its own source code concatenated with a lorem ipsum text & different levenshtein distance 1 edits applied

#let (fnv_init, fnv_step) = {
  let fnv_prime = 16777619
  let wrap_val = calc.div-euclid(int.max, fnv_prime)

  (2166136261, (a, c) => calc.rem(a.bit-xor(c), wrap_val) * fnv_prime)
}

#let wrap_del = (b, idx) => {
  let a = b.slice(0, idx).fold(fnv_init, fnv_step)
  b.slice(idx + 1, none).fold(a, fnv_step)
}

#let wrap_ins = (b, idx, val) => {
  let a = b.slice(0, idx).fold(fnv_init, fnv_step)
  a = fnv_step(a, val)
  b.slice(idx, none).fold(a, fnv_step)
}

#let wrap_sub = (b, idx, val) => {
  let a = b.slice(0, idx).fold(fnv_init, fnv_step)
  a = fnv_step(a, val)
  b.slice(idx + 1, none).fold(a, fnv_step)
}


#let b = array(bytes((read("cht.typ"), lorem(128)).join()))

#let hashes = {
  import "@preview/suiji:0.5.1": gen-rng-f, integers-f

  let rng = gen-rng-f(8)

  let hashes = (str(b.fold(fnv_init, fnv_step)): ("none",))

  let (o, k, v) = (none,) * 3
  for i in range(b.len()) {
    // deletions for i where x[i] == x[i+1] yield the same output, guard against this case
    if ((i + 1) < b.len() and (b.at(i) != b.at(i + 1))) {
      (o, k) = (str(wrap_del(b, i)), "del:" + str(i))
      if o in hashes {
        hashes.at(o).push(k)
      } else {
        hashes.insert(str(o), (k,))
      }
    }

    (rng, v) = integers-f(rng, low: 1, high: 256)
    v = calc.rem-euclid(b.at(i) + v, 256)
    (o, k) = (str(wrap_ins(b, i, v)), "ins:" + str(i) + "," + str(v))
    if o in hashes {
      hashes.at(o).push(k)
    } else {
      hashes.insert(str(o), (k,))
    }

    (rng, v) = integers-f(rng, low: 1, high: 256)
    v = calc.rem-euclid(b.at(i) + v, 256)
    (o, k) = (str(wrap_sub(b, i, v)), "sub:" + str(i) + "," + str(v))
    if o in hashes {
      hashes.at(o).push(k)
    } else {
      hashes.insert(str(o), (k,))
    }
  }

  hashes
}

number of unique hashes / total number of hashes: #hashes.len() / #hashes.values().map(e => e.len()).sum()

colliding hashes: #hashes.filter(v => v.len() > 1)
