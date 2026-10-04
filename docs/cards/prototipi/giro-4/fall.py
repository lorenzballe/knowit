from manim import *
config.pixel_width = 1080
config.pixel_height = 1080
config.frame_width = 9
config.frame_height = 9
config.background_color = "#0f1412"
config.frame_rate = 30
COLS = ["#00E5A0", "#FFD84D", "#4CC3FF", "#FF7AB6", "#B78CFF"]
F = "Figtree"
N = 5

class Fall(Scene):
    def construct(self):
        # left: the fall, to scale; right: the same seconds as squares
        top, bottom, rx = 3.3, -3.35, -3.3
        u = (top - bottom) / (N * N)
        ruler = Line([rx, top, 0], [rx, bottom, 0], color=GREY_D, stroke_width=3)
        stone = Circle(radius=0.22, fill_color=WHITE, fill_opacity=1, stroke_width=0).move_to([rx, top, 0])
        head = Text("THE FALL", font=F, weight=BOLD, font_size=20, color=GREY_B).next_to(ruler, UP, buff=0.15).shift(UP * 0.05)
        s = 0.72
        gx, gy = 0.9, -1.35
        origin = np.array([gx - (N - 1) * s / 2, gy + (N - 1) * s / 2, 0])
        self.add(ruler, head, stone)
        eq = None
        terms, total = [], 0
        for n in range(1, N + 1):
            odd = 2 * n - 1; total += odd; terms.append(str(odd)); col = COLS[n - 1]
            y0, y1 = top - (n - 1) ** 2 * u, top - n * n * u
            seg = Line([rx, y0, 0], [rx, y1, 0], color=col, stroke_width=12)
            tick = Text(f"{n} s", font=F, weight=BOLD, font_size=22, color=col).move_to([rx - 0.55, y1, 0])
            cells = VGroup()
            for i in range(n):
                for j in range(n):
                    if i == n - 1 or j == n - 1:
                        cells.add(RoundedRectangle(corner_radius=0.06, width=s * .88, height=s * .88, stroke_width=0, fill_color=col, fill_opacity=1).move_to(origin + np.array([j * s, -i * s, 0])))
            new_eq = VGroup(
                Text(" + ".join(terms), font=F, weight=BOLD, font_size=40, color=WHITE),
                Text(f"= {total} = {n} × {n}", font=F, weight=BOLD, font_size=40, color=col),
            ).arrange(DOWN, aligned_edge=LEFT, buff=0.2).move_to([1.05, 3.0, 0], aligned_edge=UL).shift(LEFT * 1.6)
            rt = 1.0 if n < 3 else 0.8
            anims = [stone.animate(rate_func=lambda t: t * t).move_to([rx, y1, 0]), Create(seg),
                     LaggedStart(*[GrowFromCenter(c) for c in cells], lag_ratio=0.06)]
            anims.append(FadeIn(new_eq) if eq is None else ReplacementTransform(eq, new_eq))
            self.play(*anims, run_time=rt)
            self.add(seg, stone)
            self.play(FadeIn(tick, shift=LEFT * 0.1), run_time=0.25)
            eq = new_eq
            self.wait(0.25)
        final = Text("Speed keeps growing: distance = time × time.", font=F, weight=MEDIUM, font_size=24, color=WHITE)
        final.move_to([0.75, -3.95, 0])
        self.play(FadeIn(final, shift=UP * 0.1), run_time=0.5)
        self.wait(1.6)
