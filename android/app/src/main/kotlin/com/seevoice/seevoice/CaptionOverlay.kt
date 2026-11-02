package com.seevoice.seevoice

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import kotlin.math.abs

/**
 * App 在后台时显示的半透明浮动字幕窗口（PRD 4.7）。
 *
 * 顶部为拖动条（上下拖动移动窗口）、“麦克风 | 喇叭”声音来源选择（PRD 4.8）、“返回”与“退出”按钮；
 * 点击“退出”后顶部改为“确定退出？”确认栏，[CONFIRM_SECONDS] 秒内无操作自动恢复，识别不中断；
 * 下方为可上下滑动的字幕区：
 * 历史记录在上、当前识别在最底部，内容贴底排列，窗口能容纳几条历史就显示几条。
 * 用户向上滑动查看历史时暂停自动跟随，滑回底部后恢复。
 */
class CaptionOverlay(
    private val context: Context,
    /** 用户选择声音来源：true 为喇叭（系统播放的声音），false 为麦克风。 */
    private val onSelectSystemAudio: (Boolean) -> Unit,
    /** 用户点击“退出”：结束识别并关闭 App。 */
    private val onExit: () -> Unit,
) {
    private val windowManager = context.getSystemService(WindowManager::class.java)
    private var root: View? = null
    private var scroll: ScrollView? = null
    private var historyBox: LinearLayout? = null
    private var currentView: TextView? = null
    private var micOption: TextView? = null
    private var speakerOption: TextView? = null
    private var style: Style? = null
    private var labels: Labels? = null
    private var controls: View? = null
    private var confirmBar: View? = null
    private var cancelButton: TextView? = null
    private val handler = Handler(Looper.getMainLooper())
    private var countdown = 0
    private val tick = object : Runnable {
        override fun run() {
            countdown--
            if (countdown <= 0) {
                cancelExit()
            } else {
                cancelButton?.text = cancelLabel()
                handler.postDelayed(this, 1000)
            }
        }
    }
    private var shownHistory: List<String> = emptyList()

    /** 是否停在底部；为 true 时新内容到来自动滚到底。 */
    private var followBottom = true

    data class Style(
        val heightFraction: Double,
        val background: Int,
        val focusColor: Int,
        val historyColor: Int,
        val focusSize: Float,
        val historySize: Float,
        val historyBold: Boolean,
    )

    /** 按界面语言显示的按钮文字，由 Dart 端传入。 */
    data class Labels(
        val microphone: String,
        val speaker: String,
        val back: String,
        val exit: String,
        val confirmExit: String,
        val cancel: String,
    )

    fun canShow(): Boolean = Settings.canDrawOverlays(context)

    fun show(style: Style, labels: Labels) {
        if (root != null || !canShow()) return
        this.style = style
        this.labels = labels
        val metrics = context.resources.displayMetrics
        val height = (metrics.heightPixels * style.heightFraction).toInt()
        val margin = dp(12)

        val header = buildHeader(style, labels)

        val history = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        val current = TextView(context).apply {
            setTextColor(style.focusColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, style.focusSize)
            setTypeface(typeface, Typeface.BOLD)
            setLineSpacing(0f, 1.2f)
            visibility = View.GONE
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.BOTTOM
            addView(history)
            addView(current)
        }
        val scrollView = ScrollView(context).apply {
            isFillViewport = true
            isVerticalScrollBarEnabled = true
            overScrollMode = View.OVER_SCROLL_NEVER
            addView(content)
            setOnScrollChangeListener { v, _, _, _, _ ->
                followBottom = !v.canScrollVertically(1)
            }
        }

        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(header)
            addView(
                scrollView,
                LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
            )
        }
        val frame = FrameLayout(context).apply {
            background = GradientDrawable().apply {
                setColor(style.background)
                cornerRadius = dp(16).toFloat()
            }
            setPadding(dp(16), dp(4), dp(16), dp(12))
            addView(column)
        }

        val lp = WindowManager.LayoutParams(
            metrics.widthPixels - margin * 2,
            height,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = margin
            // 默认放在屏幕下方三分之一，留出导航栏的位置。
            y = metrics.heightPixels - height - dp(64)
        }
        enableDrag(header, frame, lp)
        windowManager.addView(frame, lp)

        root = frame
        scroll = scrollView
        historyBox = history
        currentView = current
        shownHistory = emptyList()
        followBottom = true
    }

    /** [history] 旧的在前；[systemAudio] 为当前是否识别系统声音。 */
    fun update(current: String, partial: Boolean, history: List<String>, systemAudio: Boolean) {
        val follow = followBottom
        renderSource(systemAudio)
        if (history != shownHistory) setHistory(history)
        currentView?.apply {
            text = current
            alpha = if (partial) 0.7f else 1f
            visibility = if (current.isEmpty()) View.GONE else View.VISIBLE
        }
        if (follow) scroll?.post { scroll?.fullScroll(View.FOCUS_DOWN) }
    }

    fun hide() {
        handler.removeCallbacks(tick)
        root?.let { windowManager.removeView(it) }
        root = null
        scroll = null
        historyBox = null
        currentView = null
        micOption = null
        speakerOption = null
        controls = null
        confirmBar = null
        cancelButton = null
        shownHistory = emptyList()
    }

    /** 点击“退出”：显示确认栏并开始倒计时，避免误触直接退出。 */
    private fun askExit() {
        countdown = CONFIRM_SECONDS
        cancelButton?.text = cancelLabel()
        controls?.visibility = View.GONE
        confirmBar?.visibility = View.VISIBLE
        handler.removeCallbacks(tick)
        handler.postDelayed(tick, 1000)
    }

    /** 取消或超时：恢复正常的顶部按钮，浮动窗继续工作。 */
    private fun cancelExit() {
        handler.removeCallbacks(tick)
        confirmBar?.visibility = View.GONE
        controls?.visibility = View.VISIBLE
    }

    private fun cancelLabel() = "${labels?.cancel} ($countdown)"

    private fun setHistory(history: List<String>) {
        val box = historyBox ?: return
        val style = style ?: return
        box.removeAllViews()
        for (line in history) {
            box.addView(TextView(context).apply {
                text = line
                setTextColor(style.historyColor)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, style.historySize)
                setLineSpacing(0f, 1.15f)
                if (style.historyBold) setTypeface(typeface, Typeface.BOLD)
                setPadding(0, dp(2), 0, dp(2))
            })
        }
        shownHistory = history
    }

    private fun buildHeader(style: Style, labels: Labels): LinearLayout {
        val grip = TextView(context).apply {
            text = "≡"
            setTextColor(style.historyColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 20f)
            alpha = 0.6f
        }
        fun option(label: String, systemAudio: Boolean) = TextView(context).apply {
            text = label
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            setPadding(dp(10), dp(4), dp(10), dp(4))
            setOnClickListener { onSelectSystemAudio(systemAudio) }
        }
        val mic = option(labels.microphone, false)
        val speaker = option(labels.speaker, true)
        micOption = mic
        speakerOption = speaker
        renderSource(false)
        val source = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            background = GradientDrawable().apply {
                cornerRadius = dp(14).toFloat()
                setStroke(dp(1), style.historyColor)
            }
            addView(mic)
            addView(speaker)
        }
        val back = TextView(context).apply {
            text = labels.back
            setTextColor(style.historyColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setPadding(dp(12), dp(6), 0, dp(6))
            setOnClickListener { openApp() }
        }
        val exit = TextView(context).apply {
            text = labels.exit
            setTextColor(style.historyColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setPadding(dp(12), dp(6), 0, dp(6))
            setOnClickListener { askExit() }
        }
        val normal = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(source)
            addView(back)
            addView(exit)
        }

        val question = TextView(context).apply {
            text = labels.confirmExit
            setTextColor(style.focusColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setTypeface(typeface, Typeface.BOLD)
        }
        val confirm = TextView(context).apply {
            text = labels.exit
            setTextColor(0xFFFFFFFF.toInt())
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setPadding(dp(14), dp(6), dp(14), dp(6))
            background = GradientDrawable().apply {
                cornerRadius = dp(14).toFloat()
                setColor(0xFFD32F2F.toInt())
            }
            setOnClickListener {
                cancelExit()
                onExit()
            }
        }
        val cancel = TextView(context).apply {
            setTextColor(style.historyColor)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setPadding(dp(14), dp(6), dp(4), dp(6))
            setOnClickListener { cancelExit() }
        }
        val confirmRow = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            visibility = View.GONE
            addView(question)
            addView(View(context), LinearLayout.LayoutParams(dp(12), 1))
            addView(confirm)
            addView(cancel)
        }
        controls = normal
        confirmBar = confirmRow
        cancelButton = cancel

        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(32)
            addView(grip)
            addView(View(context), LinearLayout.LayoutParams(0, 1, 1f))
            addView(normal)
            addView(confirmRow)
        }
    }

    /** 当前来源实心高亮，另一项透明。 */
    private fun renderSource(systemAudio: Boolean) {
        val style = style ?: return
        listOf(micOption to !systemAudio, speakerOption to systemAudio).forEach { (view, on) ->
            view ?: return@forEach
            view.setTextColor(if (on) style.background or 0xFF000000.toInt() else style.historyColor)
            view.background = if (on) GradientDrawable().apply {
                cornerRadius = dp(14).toFloat()
                setColor(style.historyColor)
            } else null
        }
    }

    /** 只在拖动条上拖动窗口，字幕区的滑动留给历史滚动。 */
    @SuppressLint("ClickableViewAccessibility")
    private fun enableDrag(handle: View, window: View, lp: WindowManager.LayoutParams) {
        val slop = ViewConfiguration.get(context).scaledTouchSlop
        var startY = 0f
        var startParamY = 0
        var dragging = false
        handle.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    startY = event.rawY
                    startParamY = lp.y
                    dragging = false
                }
                MotionEvent.ACTION_MOVE -> {
                    val dy = event.rawY - startY
                    if (abs(dy) > slop) dragging = true
                    if (dragging) {
                        val maxY = context.resources.displayMetrics.heightPixels - lp.height
                        lp.y = (startParamY + dy.toInt()).coerceIn(0, maxY)
                        windowManager.updateViewLayout(window, lp)
                    }
                }
            }
            // “返回”按钮自身可点击，会先于此处消费点击；其余区域的触摸用于拖动。
            true
        }
    }

    private fun openApp() {
        context.startActivity(
            Intent(context, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            )
        )
    }

    private companion object {
        /** 退出确认栏无操作时自动恢复的秒数。 */
        const val CONFIRM_SECONDS = 5
    }

    private fun dp(value: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value.toFloat(), context.resources.displayMetrics
    ).toInt()
}
