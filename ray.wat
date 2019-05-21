(import "Math" "sin" (func $sin (param f32) (result f32)))

(memory (export "mem") 4)

(global $time (mut f32) (f32.const 0))
(global $t0 (mut f32) (f32.const 0))
(global $rsx (mut f32) (f32.const 0))
(global $rsy (mut f32) (f32.const 0))
(global $rsz (mut f32) (f32.const 0))
(global $rdx (mut f32) (f32.const 0))
(global $rdy (mut f32) (f32.const 0))
(global $rdz (mut f32) (f32.const 0))
(global $r (mut f32) (f32.const 0))
(global $g (mut f32) (f32.const 0))
(global $b (mut f32) (f32.const 0))

(func $pos (param i32 f32 f32 f32 f32)
  (f32.store (local.get 0)
    (f32.add
      (f32.mul
        (local.get 1)
        (call $sin
          (f32.add
            (f32.mul (global.get $time) (local.get 2))
            (local.get 3))))
      (local.get 4))))

;; 0: spheres: x, y, z, r
(func $update
  ;; ground
  (f32.store (i32.const 0)  (f32.const    0))
  (f32.store (i32.const 4)  (f32.const  100))
  (f32.store (i32.const 8)  (f32.const    0))
  (f32.store (i32.const 12) (f32.const   97))

  ;; sphere 1
  (call $pos (i32.const 16) (f32.const 10) (f32.const 0.3) (f32.const 0) (f32.const 0))
  (call $pos (i32.const 20) (f32.const -2.3) (f32.const 0.5) (f32.const 0) (f32.const -2.5))
  (call $pos (i32.const 24) (f32.const  7) (f32.const 1.1) (f32.const 1.57) (f32.const -10))
  (f32.store (i32.const 28) (f32.const  1.7))

  ;; sphere 2
  (call $pos (i32.const 32) (f32.const 3.5) (f32.const -0.5) (f32.const 0.78) (f32.const 0))
  (call $pos (i32.const 36) (f32.const 4.7) (f32.const 1.3) (f32.const 0) (f32.const -0.5))
  (call $pos (i32.const 40) (f32.const 3.5) (f32.const -2.1) (f32.const 4.71) (f32.const -13))
  (f32.store (i32.const 44) (f32.const   0.4))

  ;; sphere 3
  (call $pos (i32.const 48) (f32.const 3.5) (f32.const 1.1) (f32.const 1.57) (f32.const 0))
  (call $pos (i32.const 52) (f32.const -1.2) (f32.const 4.0) (f32.const 0) (f32.const 1.5))
  (call $pos (i32.const 56) (f32.const 1.5) (f32.const -1.2) (f32.const 0) (f32.const -15))
  (f32.store (i32.const 60) (f32.const   1.3))
)

(func $start (call $update))
(start $start)

(func $ray_sphere (param $s i32) (result f32)
  (local $Lx f32)
  (local $Ly f32)
  (local $Lz f32)
  (local $b f32)
  (local $r f32)
  (local $d2 f32)

  (local.set $d2
    (f32.add
      (f32.sub
        (f32.mul
          (local.tee $b
            (f32.add
              (f32.add
                (f32.mul
                  (local.tee $Lx
                    (f32.sub
                      (f32.load offset=0 (local.get $s))
                      (global.get $rsx)))
                  (global.get $rdx))
                (f32.mul
                  (local.tee $Ly
                    (f32.sub
                      (f32.load offset=4 (local.get $s))
                      (global.get $rsy)))
                  (global.get $rdy)))
              (f32.mul
                (local.tee $Lz
                  (f32.sub
                    (f32.load offset=8 (local.get $s))
                    (global.get $rsz)))
                (global.get $rdz))))
          (local.get $b))
        (f32.add
          (f32.add
            (f32.mul (local.get $Lx) (local.get $Lx))
            (f32.mul (local.get $Ly) (local.get $Ly)))
          (f32.mul (local.get $Lz) (local.get $Lz))))
      (f32.mul
        (local.tee $r (f32.load offset=12 (local.get $s)))
        (local.get $r))))

  (if (result f32)
    (f32.gt (local.get $d2) (f32.const 0))
    (if (result f32)
      (f32.gt
        (local.tee $r
          (f32.sub (local.get $b) (local.tee $d2 (f32.sqrt (local.get $d2)))))
        (f32.const 1e-4))
      (local.get $r)
      (if (result f32)
        (f32.gt
          (local.tee $r (f32.add (local.get $b) (local.get $d2)))
          (f32.const 1e-4))
        (local.get $r)
        (f32.const inf)))
    (f32.const inf)))

(func $scene (result i32)
  (local $s i32)
  (local $smin i32)
  (local $t0 f32)

  (local.set $smin (i32.const -1))
  (global.set $t0 (f32.const inf))

  (loop
    (if
      (f32.lt
        (local.tee $t0 (call $ray_sphere (local.get $s)))
        (global.get $t0))
      (then
        (global.set $t0 (local.get $t0))
        (local.set $smin (local.get $s))))
    (br_if 0
      (i32.ne
        (local.tee $s (i32.add (local.get $s) (i32.const 16)))
        (i32.const 64))))
  (local.get $smin))

(func $accum (param $r f32) (param $g f32) (param $b f32) (param $scale f32)
  (global.set $r
    (f32.add (global.get $r) (f32.mul (local.get $r) (local.get $scale))))
  (global.set $g
    (f32.add (global.get $g) (f32.mul (local.get $g) (local.get $scale))))
  (global.set $b
    (f32.add (global.get $b) (f32.mul (local.get $b) (local.get $scale)))))

(func $scene_col
  (local $bounce i32)
  (local $scale f32)
  (local $smin i32)
  (local $dot f32)
  (local $dx f32)
  (local $dy f32)
  (local $dz f32)
  (local $nx f32)
  (local $ny f32)
  (local $nz f32)

  (local.set $bounce (i32.const 3))
  (local.set $scale (f32.const 1))

  (loop $loop
    (if
      (i32.ge_s
        (local.tee $smin (call $scene))
        (i32.const 0))
      (then
        (global.set $t0 (f32.sub (global.get $t0) (f32.const 1e-2))) ;; nudge

        ;; save dir
        (local.set $dx (global.get $rdx))
        (local.set $dy (global.get $rdy))
        (local.set $dz (global.get $rdz))

        ;; new pos
        (global.set $rsx
          (f32.add (global.get $rsx) (f32.mul (local.get $dx) (global.get $t0))))
        (global.set $rsy
          (f32.add (global.get $rsy) (f32.mul (local.get $dy) (global.get $t0))))
        (global.set $rsz
          (f32.add (global.get $rsz) (f32.mul (local.get $dz) (global.get $t0))))

        ;; normal
        (global.set $rdx
          (f32.sub (global.get $rsx) (f32.load offset=0 (local.get $smin))))
        (global.set $rdy
          (f32.sub (global.get $rsy) (f32.load offset=4 (local.get $smin))))
        (global.set $rdz
          (f32.sub (global.get $rsz) (f32.load offset=8 (local.get $smin))))
        (call $norm)

        ;; save normal
        (local.set $nx (global.get $rdx))
        (local.set $ny (global.get $rdy))
        (local.set $nz (global.get $rdz))

        ;; light dir
        (global.set $rdx (f32.sub (f32.const -1) (global.get $rsx)))
        (global.set $rdy (f32.sub (f32.const -9) (global.get $rsy)))
        (global.set $rdz (f32.sub (f32.const -2) (global.get $rsz)))
        (call $norm)

        (call $accum
          (f32.const 0.1) (f32.const 0.1) (f32.const 0.1) (local.get $scale))

        ;; do shadow
        (if
          (i32.lt_s (call $scene) (i32.const 0))
          (then
            (local.set $dot
              (f32.max
                (f32.add
                  (f32.add
                    (f32.mul (global.get $rdx) (local.get $nx))
                    (f32.mul (global.get $rdy) (local.get $ny)))
                  (f32.mul (global.get $rdz) (local.get $nz)))
                (f32.const 0)))

            (call $accum
              (f32.mul (f32.const 0.16) (local.get $dot))
              (f32.mul (f32.const 0.32) (local.get $dot))
              (f32.mul (f32.const 0.72) (local.get $dot))
              (local.get $scale))))

        ;; do reflect
        (if
          (local.tee $bounce (i32.sub (local.get $bounce) (i32.const 1)))
          (then
            ;; reflect D across N
            (local.set $dot
              (f32.mul
                (f32.add
                  (f32.add
                    (f32.mul (local.get $dx) (local.get $nx))
                    (f32.mul (local.get $dy) (local.get $ny)))
                  (f32.mul (local.get $dz) (local.get $nz)))
                (f32.const 2)))
            (global.set $rdx
              (f32.sub (local.get $dx) (f32.mul (local.get $nx) (local.get $dot))))
            (global.set $rdy
              (f32.sub (local.get $dy) (f32.mul (local.get $ny) (local.get $dot))))
            (global.set $rdz
              (f32.sub (local.get $dz) (f32.mul (local.get $nz) (local.get $dot))))

            ;; loop w/ reflection ray in fainter color
            (local.set $scale (f32.mul (local.get $scale) (f32.const 0.2)))
            (br $loop))) )
      (else
        (call $accum
          (f32.const 0.7) (f32.const 0.4) (f32.const 0.3) (local.get $scale))
      )
    )
  )
)

(func $norm
  (local $temp f32)
  (local $x f32)
  (local $y f32)
  (local $z f32)
  (local.set $temp
    (f32.sqrt
      (f32.add
        (f32.add
          (f32.mul (local.tee $x (global.get $rdx)) (local.get $x))
          (f32.mul (local.tee $y (global.get $rdy)) (local.get $y)))
        (f32.mul (local.tee $z (global.get $rdz)) (local.get $z)))))
  (global.set $rdx (f32.div (local.get $x) (local.get $temp)))
  (global.set $rdy (f32.div (local.get $y) (local.get $temp)))
  (global.set $rdz (f32.div (local.get $z) (local.get $temp))))

(func $col (param f32) (result i32)
  (i32.trunc_f32_s
    (f32.mul
      (f32.min
        (f32.max (local.get 0) (f32.const 0))
        (f32.const 1))
      (f32.const 255))))

(func (export "run") (param $time f32)
  (local $x i32)
  (local $y i32)
  (local $hit f32)

  (global.set $time (f32.mul (local.get $time) (f32.const 0.0008)))

  (call $update)

  (loop $yloop

    (local.set $x (i32.const 0))
    (loop $xloop

      (global.set $r (f32.const 0))
      (global.set $g (f32.const 0))
      (global.set $b (f32.const 0))

      (global.set $rsx (f32.const 0))
      (global.set $rsy (f32.const 0))
      (global.set $rsz (f32.const 0))

      (global.set $rdx
        (f32.sub
          (f32.mul
            (f32.const 0.005578517393521942)
            (f32.convert_i32_s (local.get $x)))
          (f32.const 0.8897735242667496)))
      (global.set $rdy
        (f32.sub
          (f32.mul
            (f32.const 0.0055785173935219414)
            (f32.convert_i32_s (local.get $y)))
          (f32.const 0.5550624806554332)))
      (global.set $rdz (f32.const -1))
      (call $norm)

      (call $scene_col)

      ;; draw pixel
      (i32.store offset=1024
        (i32.shl
          (i32.add
            (i32.mul (local.get $y) (i32.const 320))
            (local.get $x))
          (i32.const 2))
        (i32.or
          (i32.const 0xff000000)
          (i32.or
            (i32.shl (call $col (global.get $b)) (i32.const 16))
            (i32.or
              (i32.shl (call $col (global.get $g)) (i32.const 8))
              (call $col (global.get $r))))))

      ;; loop on x
      (br_if $xloop
        (i32.ne
          (local.tee $x (i32.add (local.get $x) (i32.const 1)))
          (i32.const 320))))

    ;; loop on y
    (br_if $yloop
      (i32.ne
        (local.tee $y (i32.add (local.get $y) (i32.const 1)))
        (i32.const 200)))))
