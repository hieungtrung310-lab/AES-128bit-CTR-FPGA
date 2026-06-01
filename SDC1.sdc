# =============================================================================
#  SDC Constraints — AES-CTR-256 UART trên FPGA DE2 (Cyclone II EP2C35F672C6)
#  Top-level entity : uart_aes_top
#  Clock            : CLOCK_50 = 50 MHz
#  Tool             : Quartus II 13.0.1 / TimeQuest Timing Analyzer
# =============================================================================


# -----------------------------------------------------------------------------
# 1. CLOCK DEFINITION
# -----------------------------------------------------------------------------

# Clock chính 50 MHz từ board DE2
# Period = 20 ns  |  Duty cycle 50%  |  Rise=0 ns, Fall=10 ns
create_clock -name CLOCK_50 \
             -period 20.000 \
             -waveform {0.000 10.000} \
             [get_ports CLOCK_50]

# Thêm clock uncertainty để tính jitter và skew của PLL/oscillator trên board
set_clock_uncertainty -rise_from [get_clocks CLOCK_50] \
                      -rise_to   [get_clocks CLOCK_50] \
                      0.200
set_clock_uncertainty -fall_from [get_clocks CLOCK_50] \
                      -fall_to   [get_clocks CLOCK_50] \
                      0.200


# -----------------------------------------------------------------------------
# 2. GENERATED CLOCK (nếu sau này dùng PLL)
# -----------------------------------------------------------------------------
# Hiện tại thiết kế không dùng PLL. Nếu thêm PLL sau này, khai báo tại đây:
# create_generated_clock -name clk_pll \
#                        -source [get_ports CLOCK_50] \
#                        -multiply_by 2 \
#                        [get_pins u_pll|clk0]


# -----------------------------------------------------------------------------
# 3. INPUT DELAYS
# -----------------------------------------------------------------------------
# UART_RXD: tín hiệu nối tiếp 9600 baud — thay đổi cực kỳ chậm so với 50 MHz.
# Bộ thu uart_rx dùng oversampling 16x, không cần timing chặt.
# Giả định board-level delay (trace + USB-Serial chip) ≈ 5 ns.
set_input_delay -clock CLOCK_50 -max  5.000 [get_ports UART_RXD]
set_input_delay -clock CLOCK_50 -min  0.000 [get_ports UART_RXD]

# KEY[0]: nút nhấn reset, tín hiệu không đồng bộ → khai báo false path bên dưới
# Không cần set_input_delay cho reset bất đồng bộ


# -----------------------------------------------------------------------------
# 4. OUTPUT DELAYS
# -----------------------------------------------------------------------------
# UART_TXD: tín hiệu đầu ra nối tiếp 9600 baud — thay đổi rất chậm.
# Chip USB-Serial trên board DE2 có thể chịu được skew lớn.
set_output_delay -clock CLOCK_50 -max  5.000 [get_ports UART_TXD]
set_output_delay -clock CLOCK_50 -min -2.000 [get_ports UART_TXD]

# LEDG[0]: LED hiển thị trạng thái — không có yêu cầu timing nghiêm ngặt
set_output_delay -clock CLOCK_50 -max  5.000 [get_ports LEDG[0]]
set_output_delay -clock CLOCK_50 -min -2.000 [get_ports LEDG[0]]


# -----------------------------------------------------------------------------
# 5. FALSE PATHS — Reset bất đồng bộ
# -----------------------------------------------------------------------------
# KEY[0] là reset active-low, bất đồng bộ (negedge KEY[0] trong always_ff).
# Không phân tích timing đường này vì không qua flip-flop đồng bộ.
set_false_path -from [get_ports {KEY[0]}]

# Output LED cũng không cần đồng bộ với clock ngoài
set_false_path -to [get_ports {LEDG[0]}]


# -----------------------------------------------------------------------------
# 6. MULTICYCLE PATHS
# -----------------------------------------------------------------------------
# key_expansion: logic tổ hợp sâu (S-box × 28 + XOR tree).
# Toàn bộ được tính trong 1 chu kỳ (không có register trong key_expansion),
# nhưng chỉ cần kết quả ổn định trước khi lõi AES bắt đầu.
# Đường từ key port đến rkey[i] là tổ hợp thuần → TimeQuest tự phân tích.
# Nếu Fmax bị giới hạn bởi key_expansion, có thể dùng multicycle 2 chu kỳ:
#
# set_multicycle_path -from [get_keepers {*key_expansion*}] \
#                     -to   [get_keepers {*rkey*}] \
#                     -setup 2
# set_multicycle_path -from [get_keepers {*key_expansion*}] \
#                     -to   [get_keepers {*rkey*}] \
#                     -hold  1
#
# Hiện tại Fmax = 140 MHz >> 50 MHz nên không cần thiết.


# -----------------------------------------------------------------------------
# 7. CUT — Bỏ qua phân tích giữa các clock domain khác nhau
# -----------------------------------------------------------------------------
# Thiết kế chỉ có 1 clock domain (CLOCK_50) nên không cần cut.
# Nếu sau này thêm CLOCK_27 hoặc PLL:
# set_clock_groups -asynchronous \
#                  -group [get_clocks CLOCK_50] \
#                  -group [get_clocks CLOCK_27]


# =============================================================================
# GHI CHÚ TIMING SUMMARY (từ kết quả Quartus II thực tế):
#   Fmax (Slow Model, CLOCK_50) = 136 MHz  →  slack = +12.86 ns @ 50 MHz
#   Setup slack   : dương (không có violation)
#   Hold  slack   : dương (không có violation)
#   Recovery slack: áp dụng cho async reset KEY[0] — đã false_path
# =============================================================================
