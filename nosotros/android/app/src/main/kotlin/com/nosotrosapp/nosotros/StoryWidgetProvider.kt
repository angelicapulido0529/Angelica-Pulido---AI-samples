package com.nosotrosapp.nosotros

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * Widget de la pantalla de inicio. Lee las fotos que la app guardó en el
 * teléfono, así que funciona sin internet. Oculta las stories que ya
 * cumplieron 24 horas.
 */
class StoryWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.story_widget)
            fillSide(views, widgetData, "me", R.id.me_image, R.id.me_empty,
                R.id.me_avatar, R.id.me_name, "Sube tu story")
            fillSide(views, widgetData, "partner", R.id.partner_image, R.id.partner_empty,
                R.id.partner_avatar, R.id.partner_name, "Sin story")

            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
                ?: Intent(context, MainActivity::class.java)
            val pending = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.widget_root, pending)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun fillSide(
        views: RemoteViews,
        data: SharedPreferences,
        side: String,
        imageId: Int,
        emptyId: Int,
        avatarId: Int,
        nameId: Int,
        emptyText: String,
    ) {
        views.setTextViewText(nameId, data.getString("${side}_name", "") ?: "")

        val avatar = data.getString("${side}_avatar", null)?.let { decode(it, 160) }
        if (avatar != null) {
            views.setImageViewBitmap(avatarId, circle(avatar))
            views.setViewVisibility(avatarId, View.VISIBLE)
        } else {
            views.setViewVisibility(avatarId, View.GONE)
        }

        val expires = data.getString("${side}_expires", null)?.toLongOrNull() ?: 0L
        val path = data.getString("${side}_image", null)
        val image = if (path != null && expires > System.currentTimeMillis()) {
            decode(path, 700)
        } else null

        if (image != null) {
            views.setImageViewBitmap(imageId, image)
            views.setViewVisibility(imageId, View.VISIBLE)
            views.setViewVisibility(emptyId, View.GONE)
        } else {
            views.setViewVisibility(imageId, View.GONE)
            views.setViewVisibility(emptyId, View.VISIBLE)
            views.setTextViewText(emptyId, emptyText)
        }
    }

    /** Carga la foto reducida: los widgets tienen un límite de memoria. */
    private fun decode(path: String, maxSide: Int): Bitmap? {
        val file = File(path)
        if (!file.exists()) return null
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeFile(path, bounds)
        var sample = 1
        while (bounds.outWidth / (sample * 2) >= maxSide &&
            bounds.outHeight / (sample * 2) >= maxSide) {
            sample *= 2
        }
        return BitmapFactory.decodeFile(path, BitmapFactory.Options().apply { inSampleSize = sample })
    }

    private fun circle(src: Bitmap): Bitmap {
        val size = minOf(src.width, src.height)
        val out = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(out)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        canvas.drawBitmap(src, ((size - src.width) / 2f), ((size - src.height) / 2f), paint)
        return out
    }
}
