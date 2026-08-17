package android.support.v4.util;

/**
 * Compatibility bridge for AMap's legacy heatmap implementation.
 *
 * <p>AMap 11.1.001's {@code HeatmapTileProvider} still links against the old
 * Support Library class name even though the SDK does not declare that
 * dependency. Android's framework implementation has the binary-compatible
 * constructor, {@code get(long)}, and {@code put(long, E)} methods used by the
 * provider.
 */
public final class LongSparseArray<E> extends android.util.LongSparseArray<E> {
  public LongSparseArray() {
    super();
  }
}
