"""
Generate architecture / flow diagrams for the SCMS project report.
Flat, print-friendly style rendered with matplotlib -> PNG (150 dpi).
Output: docs/report_assets/diagrams/*.png
"""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib.lines import Line2D

OUT = os.path.join(os.path.dirname(__file__), "diagrams")
os.makedirs(OUT, exist_ok=True)

# palette (calm, professional)
NAVY   = "#1f3a5f"
BLUE   = "#2f6fb0"
TEAL   = "#2a9d8f"
AMBER  = "#e9a13b"
RED    = "#c94f4f"
SLATE  = "#5b6b7b"
LIGHT  = "#eef3f8"
LIGHT2 = "#e9f5f2"
LIGHT3 = "#fdf1e0"
LIGHTR = "#f7e6e6"
INK    = "#1c2530"
WHITE  = "#ffffff"

plt.rcParams["font.family"] = "DejaVu Sans"


def box(ax, x, y, w, h, text, face=LIGHT, edge=BLUE, tc=INK, fs=10, bold=True,
        radius=0.08, lw=1.6):
    p = FancyBboxPatch((x, y), w, h,
                       boxstyle=f"round,pad=0.02,rounding_size={radius}",
                       linewidth=lw, edgecolor=edge, facecolor=face, zorder=2)
    ax.add_patch(p)
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, color=tc, zorder=3,
            fontweight="bold" if bold else "normal", wrap=True)
    return (x, y, w, h)


def arrow(ax, p1, p2, color=SLATE, lw=1.8, style="-|>", ls="-", rad=0.0,
          text=None, tfs=8, toff=(0, 0.12), tcolor=SLATE):
    a = FancyArrowPatch(p1, p2, arrowstyle=style, mutation_scale=14,
                        linewidth=lw, color=color, zorder=1,
                        connectionstyle=f"arc3,rad={rad}", linestyle=ls)
    ax.add_patch(a)
    if text:
        mx, my = (p1[0] + p2[0]) / 2 + toff[0], (p1[1] + p2[1]) / 2 + toff[1]
        ax.text(mx, my, text, ha="center", va="center", fontsize=tfs,
                color=tcolor, style="italic", zorder=4,
                bbox=dict(boxstyle="round,pad=0.15", fc=WHITE, ec="none", alpha=0.9))


def newfig(w=10, h=6):
    fig, ax = plt.subplots(figsize=(w, h))
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.axis("off")
    return fig, ax


def save(fig, name):
    path = os.path.join(OUT, name)
    fig.savefig(path, dpi=150, bbox_inches="tight", pad_inches=0.15,
                facecolor="white")
    plt.close(fig)
    print("wrote", path)


# ---------------------------------------------------------------------------
# 1. Three-tier system architecture
# ---------------------------------------------------------------------------
def diagram_architecture():
    fig, ax = newfig(10, 6.2)
    ax.text(50, 96, "Smart Complaint Management System — System Architecture",
            ha="center", fontsize=12.5, fontweight="bold", color=NAVY)

    b_flutter = box(ax, 6, 62, 30, 22,
                    "Flutter Mobile App\n(Dart · BLoC · Dio)\n\nStudent · Staff · SR · Admin",
                    face=LIGHT, edge=BLUE, fs=10)
    b_node = box(ax, 40, 62, 30, 22,
                 "Node.js / Express API\n(:3000)\n\nJWT · Prisma · Cron jobs\nresponse envelope",
                 face=LIGHT, edge=NAVY, fs=10)
    b_ai = box(ax, 40, 20, 30, 20,
               "Python FastAPI\nAI Service (:8000)\n\ngrammar · categorize\nembed · duplicate",
               face=LIGHT2, edge=TEAL, fs=10)
    b_db = box(ax, 6, 20, 26, 20,
               "PostgreSQL\n+ pgvector\n\nusers · complaints\nembeddings (768-d)",
               face=LIGHT3, edge=AMBER, fs=10)
    b_gem = box(ax, 76, 20, 20, 20,
                "Google Gemini\n\ngemini-2.5-flash\nembedding-004",
                face=LIGHTR, edge=RED, fs=9.5)
    b_fcm = box(ax, 76, 62, 20, 22,
                "Firebase Cloud\nMessaging (FCM)\n\nGoogle OAuth\n(rvce.edu.in)",
                face=LIGHT, edge=SLATE, fs=9.5)

    arrow(ax, (36, 73), (40, 73), text="HTTPS · JWT", rad=0)
    arrow(ax, (55, 62), (55, 40), text="internal HTTP", rad=0, toff=(9, 0))
    arrow(ax, (40, 30), (32, 30), text="psycopg2\npgvector", rad=0, toff=(0, 3.5))
    arrow(ax, (55, 62), (19, 40), color=AMBER, text="Prisma", rad=0.15, toff=(-6, 3))
    arrow(ax, (70, 30), (76, 30), color=RED, text="google-genai", rad=0, toff=(0, 3.2))
    arrow(ax, (70, 73), (76, 73), color=SLATE, text="push", rad=0)
    ax.text(50, 8, "Flutter never calls the AI service directly — always through the Node.js backend.",
            ha="center", fontsize=8.5, style="italic", color=SLATE)
    save(fig, "fig_architecture.png")


# ---------------------------------------------------------------------------
# 2. Conceptual feature flow (like reference Figure 1)
# ---------------------------------------------------------------------------
def diagram_features():
    fig, ax = newfig(10, 5.8)
    ax.text(50, 96, "Conceptual Feature Flow of SCMS", ha="center",
            fontsize=12.5, fontweight="bold", color=NAVY)
    center = box(ax, 38, 42, 24, 16, "SCMS\nPlatform", face=NAVY, edge=NAVY,
                 tc=WHITE, fs=12)
    feats = [
        ("Google OAuth\n(rvce.edu.in)", 6, 74, BLUE, LIGHT),
        ("Role-based\nAccess (4 roles)", 38, 78, BLUE, LIGHT),
        ("AI Grammar &\nCategory Assist", 70, 74, TEAL, LIGHT2),
        ("Duplicate\nDetection (pgvector)", 74, 46, TEAL, LIGHT2),
        ("SR Review &\nAssignment", 70, 14, AMBER, LIGHT3),
        ("SLA Tracking\n& Escalation", 38, 8, AMBER, LIGHT3),
        ("FCM Push\nNotifications", 6, 14, SLATE, LIGHT),
        ("Offline Drafts\n& Ratings", 6, 46, SLATE, LIGHT),
    ]
    for t, x, y, ec, fc in feats:
        box(ax, x, y, 22, 13, t, face=fc, edge=ec, fs=9)
        arrow(ax, (x + 11, y + (0 if y > 50 else 13)),
              (50, 50), color=SLATE, lw=1.3, rad=0.05)
    save(fig, "fig_feature_flow.png")


# ---------------------------------------------------------------------------
# 3. Complaint lifecycle / status flow
# ---------------------------------------------------------------------------
def diagram_lifecycle():
    fig, ax = newfig(10, 5.6)
    ax.text(50, 96, "Complaint Lifecycle & Status Flow", ha="center",
            fontsize=12.5, fontweight="bold", color=NAVY)
    y = 66
    steps = [
        ("SUBMITTED", BLUE, LIGHT),
        ("PENDING_SR\n_REVIEW", BLUE, LIGHT),
        ("ASSIGNED", TEAL, LIGHT2),
        ("IN_PROGRESS", TEAL, LIGHT2),
        ("RESOLVED", TEAL, LIGHT2),
        ("CLOSED", NAVY, LIGHT),
    ]
    xs = [2, 18.5, 35, 51.5, 68, 84.5]
    w = 14.5
    coords = []
    for (t, ec, fc), x in zip(steps, xs):
        coords.append(box(ax, x, y, w, 13, t, face=fc, edge=ec, fs=9))
    for i in range(len(xs) - 1):
        arrow(ax, (xs[i] + w, y + 6.5), (xs[i + 1], y + 6.5))
    # SR review branch labels
    arrow(ax, (18.5 + w, y - 1), (18.5 + w, y - 1), color=WHITE)  # noop
    ax.text(35 + w / 2, y - 3, "SR approves →", ha="center", fontsize=7.5,
            style="italic", color=TEAL)
    # SLA breach
    box(ax, 26, 30, 20, 12, "SLA_BREACHED", face=LIGHTR, edge=RED, fs=9)
    arrow(ax, (42, y), (40, 42), color=RED, ls="--", text="SLA timer\nexpires", toff=(9, 0), tcolor=RED)
    arrow(ax, (46, 36), (68, y), color=RED, ls="--", rad=-0.2,
          text="auto-escalate", tcolor=RED, toff=(0, -3))
    # rating
    box(ax, 84.5, 30, 14.5, 12, "Rated &\nClosed", face=LIGHT, edge=SLATE, fs=9)
    arrow(ax, (91.7, y), (91.7, 42), color=SLATE, text="student\nrates", toff=(7, 0))
    # SR reject branch
    box(ax, 2, 30, 14.5, 12, "Returned to\nStudent", face=LIGHTR, edge=RED, fs=8.5)
    arrow(ax, (25, y), (9, 42), color=RED, ls="--", rad=0.2,
          text="SR rejects", tcolor=RED, toff=(-6, 2))
    ax.text(50, 12, "SR = Student Representative review gate · cron jobs mark SLA breaches "
            "and auto-approve stale reviews",
            ha="center", fontsize=8.3, style="italic", color=SLATE)
    save(fig, "fig_lifecycle.png")


# ---------------------------------------------------------------------------
# 4. SR review workflow (swimlane-ish)
# ---------------------------------------------------------------------------
def diagram_sr_workflow():
    fig, ax = newfig(10, 6.0)
    ax.text(50, 96, "Student Representative (SR) Review Workflow", ha="center",
            fontsize=12.5, fontweight="bold", color=NAVY)
    lanes = [("Student", 78, LIGHT), ("AI Service", 56, LIGHT2),
             ("SR / Admin", 34, LIGHT3), ("Staff", 12, LIGHT)]
    for name, y, fc in lanes:
        ax.add_patch(FancyBboxPatch((1, y), 98, 18,
                     boxstyle="round,pad=0.01,rounding_size=0.02",
                     fc=fc, ec="#cfd8e0", lw=1, zorder=0))
        ax.text(3.5, y + 9, name, rotation=90, va="center", ha="center",
                fontsize=9, fontweight="bold", color=NAVY)

    s1 = box(ax, 10, 81, 17, 11, "Submit\ncomplaint", edge=BLUE, fs=9)
    a1 = box(ax, 32, 59, 17, 11, "Grammar +\ncategory +\nduplicate", edge=TEAL,
             face=LIGHT2, fs=8.5)
    r1 = box(ax, 54, 37, 17, 11, "SR reviews\nqueue", edge=AMBER, face=LIGHT3, fs=9)
    r2 = box(ax, 76, 37, 20, 11, "Approve &\nassign to staff", edge=AMBER,
             face=LIGHT3, fs=9)
    st1 = box(ax, 76, 15, 20, 11, "Resolve &\nupdate status", edge=TEAL, fs=9)

    arrow(ax, (27, 86), (40, 70), rad=-0.1, text="AI assist")
    arrow(ax, (40, 59), (62, 48), rad=-0.1, text="enrich")
    arrow(ax, (71, 42), (76, 42), text="")
    arrow(ax, (86, 37), (86, 26), text="notify staff (FCM)", toff=(13, 0))
    arrow(ax, (76, 20), (27, 81), color=SLATE, ls="--", rad=0.25,
          text="status updates + push notify student", toff=(0, -3))
    save(fig, "fig_sr_workflow.png")


# ---------------------------------------------------------------------------
# 5. AI-assist sequence
# ---------------------------------------------------------------------------
def diagram_ai_sequence():
    fig, ax = newfig(10, 6.2)
    ax.text(50, 97, "AI-Assisted Submission — Request Sequence", ha="center",
            fontsize=12.5, fontweight="bold", color=NAVY)
    actors = [("Flutter\napp", 12, BLUE), ("Node.js\nbackend", 37, NAVY),
              ("Python AI\nservice", 62, TEAL), ("Gemini /\npgvector", 87, RED)]
    xs = {}
    for name, x, c in actors:
        box(ax, x - 9, 84, 18, 9, name, edge=c, fs=9)
        ax.add_line(Line2D([x, x], [10, 84], color="#c7d0da", lw=1.2,
                    linestyle=(0, (4, 3)), zorder=0))
        xs[name] = x

    def msg(y, x1, x2, text, c=SLATE, dashed=False):
        arrow(ax, (x1, y), (x2, y), color=c, lw=1.6,
              ls="--" if dashed else "-")
        mid = (x1 + x2) / 2
        ax.text(mid, y + 1.6, text, ha="center", fontsize=8, color=INK,
                bbox=dict(boxstyle="round,pad=0.15", fc=WHITE, ec="none", alpha=0.9))

    F, N, A, G = 12, 37, 62, 87
    msg(76, F, N, "type description (debounced 800 ms)")
    msg(70, N, A, "POST /grammar-check")
    msg(64, A, G, "gemini-2.5-flash", c=RED)
    msg(58, A, N, "corrected text", dashed=True)
    msg(52, N, F, "grammar banner", dashed=True)
    msg(44, N, A, "POST /categorize")
    msg(38, A, N, "suggested category", dashed=True)
    msg(30, F, N, "submit complaint (+ media)")
    msg(24, N, A, "POST /embed  (after row insert)")
    msg(18, N, A, "POST /check-duplicate")
    msg(12, A, G, "cosine similarity search (pgvector)", c=RED)
    save(fig, "fig_ai_sequence.png")


# ---------------------------------------------------------------------------
# 6. Role-based navigation flow
# ---------------------------------------------------------------------------
def diagram_navigation():
    fig, ax = newfig(10, 5.8)
    ax.text(50, 96, "Role-Based Navigation Flow", ha="center",
            fontsize=12.5, fontweight="bold", color=NAVY)
    box(ax, 40, 84, 20, 10, "Splash /\nOnboarding", edge=SLATE, fs=9)
    box(ax, 40, 68, 20, 10, "Google Sign-In\n(rvce.edu.in)", edge=BLUE, fs=9)
    arrow(ax, (50, 84), (50, 78))
    dec = box(ax, 40, 52, 20, 10, "Role from JWT", edge=NAVY, face=LIGHT, fs=9)
    arrow(ax, (50, 68), (50, 62))

    roles = [
        ("STUDENT\nDashboard · Submit ·\nMy Complaints · Rate", 3, BLUE, LIGHT),
        ("STAFF\nAssigned queue ·\nUpdate status", 28, TEAL, LIGHT2),
        ("SR\nReview queue ·\nApprove · Assign", 53, AMBER, LIGHT3),
        ("ADMIN\nUsers · Depts ·\nAnalytics · Audit", 78, SLATE, LIGHT),
    ]
    for t, x, ec, fc in roles:
        box(ax, x, 22, 19, 18, t, edge=ec, face=fc, fs=8.5)
        arrow(ax, (50, 52), (x + 9.5, 40), color=ec, rad=0.05, lw=1.4)
    ax.text(50, 10, "go_router applies role-based redirects; each role sees only its permitted routes.",
            ha="center", fontsize=8.3, style="italic", color=SLATE)
    save(fig, "fig_navigation.png")


if __name__ == "__main__":
    diagram_architecture()
    diagram_features()
    diagram_lifecycle()
    diagram_sr_workflow()
    diagram_ai_sequence()
    diagram_navigation()
    print("All diagrams generated.")
