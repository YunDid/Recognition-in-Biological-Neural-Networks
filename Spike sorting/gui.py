import spikeinterface as si
import spikeinterface_gui
app = spikeinterface_gui.mkQApp()
waveforms_folder = "E:/weiwei_mong/results/时空刺激/融合脑/1028-1/2023-11-21T16-27-10McsRecording/waveforms_folder"
we = si.load_waveforms(waveforms_folder)
win = spikeinterface_gui.MainWindow(we)
win.show()
app.exec_()
