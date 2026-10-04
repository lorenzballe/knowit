from manim import *
config.pixel_width = 1080
config.pixel_height = 1080
config.frame_width = 9
config.frame_height = 9
config.background_color = "#0f1412"
config.frame_rate = 30
COLS = ["#00E5A0", "#FFD84D", "#4CC3FF", "#FF7AB6", "#B78CFF", "#FF9A3D"]
F = "Figtree"

class OddSquares(Scene):
    def construct(self):
        s = 0.66
        n_max = 6
        origin = np.array([-(n_max - 1) * s / 2, -0.55 - (n_max - 1) * s / 2, 0])
        total = 0
        terms = []
        eq = None
        sec = Text("SECOND 1", font=F, weight=BOLD, font_size=22, color=GREY_B)
        sec.to_corner(UR, buff=0.5)
        self.add(sec)
        for n in range(1, n_max + 1):
            odd = 2 * n - 1
            total += odd
            terms.append(str(odd))
            col = COLS[(n - 1) % len(COLS)]
            cells = VGroup()
            for i in range(n):
                for j in range(n):
                    if i == n - 1 or j == n - 1:
                        sq = RoundedRectangle(corner_radius=0.06, width=s * 0.88, height=s * 0.88, stroke_width=0, fill_color=col, fill_opacity=1)
                        sq.move_to(origin + np.array([j * s, -i * s + (n_max - 1) * s, 0]))
                        cells.add(sq)
            new_eq = VGroup(
                Text(" + ".join(terms), font=F, weight=BOLD, font_size=44, color=WHITE),
                Text(f"= {total} = {n} × {n}", font=F, weight=BOLD, font_size=44, color=col),
            ).arrange(DOWN, aligned_edge=LEFT, buff=0.22).to_corner(UL, buff=0.5)
            new_sec = Text(f"SECOND {n}", font=F, weight=BOLD, font_size=22, color=GREY_B).to_corner(UR, buff=0.5)
            rt = 0.9 if n < 4 else 0.65
            anims = [LaggedStart(*[GrowFromCenter(c) for c in cells], lag_ratio=0.07, run_time=rt)]
            self.play(*anims)
            if eq is None:
                self.play(FadeIn(new_eq, shift=UP * 0.15), run_time=0.45)
            else:
                self.play(ReplacementTransform(eq, new_eq), ReplacementTransform(sec, new_sec), run_time=0.45)
                sec = new_sec
            eq = new_eq
            self.wait(0.3)
        outline = RoundedRectangle(corner_radius=0.1, width=n_max * s + 0.08, height=n_max * s + 0.08, stroke_color=WHITE, stroke_width=4)
        outline.move_to(origin + np.array([(n_max - 1) * s / 2, (n_max - 1) * s / 2, 0]))
        self.play(Create(outline), run_time=0.7)
        final = Text("Each odd number wraps the square one layer bigger.", font=F, weight=MEDIUM, font_size=24, color=WHITE)
        final.next_to(outline, DOWN, buff=0.32)
        self.play(FadeIn(final, shift=UP * 0.12), run_time=0.5)
        self.wait(1.8)
